TAGNAME ?= bertsky/ocrd_controller
SHELL = /bin/bash

build:
	docker build -t $(TAGNAME) .

define HELP
cat <<"EOF"
Targets:
	- build	(re)compile Docker image from sources
	- run	start Docker container

Variables:
	- TAGNAME	name of Docker image to build/run
	  currently: "$(TAGNAME)"
	- KEYS		file to mount as .ssh/authorized_keys
	  currently: "$(KEYS)"
	- DATA		host directory to mount into `/data`
	  currently: "$(DATA)"
	- MODELS	resource data directory to mount into `/models`
	  currently: "$(MODELS)"
	- CONFIG	resource config directory to mount into `/models`
	  currently: "$(CONFIG)"
	- UID		user id to use in logins
	  currently: $(UID)
	- GID		group id to use in logins
	  currently: $(GID)
	- UMASK		user mask to use in logins
	  currently: $(UMASK)
	- PORT		TCP port for the (host-side) sshd server
	  currently: $(PORT)
	- GTKPORT	TCP port for the (host-side) Broadwayd
	  currently: $(GTKPORT)
EOF
endef
export HELP
help: ; @eval "$$HELP"

KEYS ?= $(firstword $(wildcard $(HOME)/.ssh/authorized_keys* $(HOME)/.ssh/id_*.pub))
DATA ?= $(CURDIR)
MODELS ?= $(HOME)/.local/share
CONFIG ?= $(HOME)/.config
UID ?= $(shell id -u)
GID ?= $(shell id -g)
UMASK ?= 0002
PORT ?= 8022
GTKPORT ?= 8085
# FIXME: map host to container UIDs so that logins will modify data on volumes with host UID not as root
run: $(DATA) $(MODELS) $(KEYS)
	docker run --rm \
	-p $(PORT):22 \
	-p $(GTKPORT):8085 \
	--name ocrd_controller \
	-v $(DATA):/data \
	-v $(MODELS):/models \
	-v $(CONFIG):/config \
	--mount type=bind,source=$(KEYS),target=/authorized_keys \
	-e UID=$(UID) -e GID=$(GID) -e UMASK=$(UMASK) \
	$(TAGNAME)

.PHONY: build run help
