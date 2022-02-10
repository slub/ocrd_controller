TAGNAME ?= bertsky/ocrd_controller

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
	- KEYS		content of authorized_keys (newline-separated)
	currently: "$(KEYS)"
	- DATA		host directory to mount into `/data`
	currently: "$(CURDIR)"
	- MODELS	resource directory to mount into `/models`
	currently: "$(HOME)"
	- PORT		TCP port for the (host-side) sshd server
	currently: $(PORT)
	- GTKPORT	TCP port for the (host-side) Broadwayd
	currently: $(GTKPORT)
EOF
endef
export HELP
help: ; @eval "$$HELP"

KEYS ?= $(shell cat $(HOME)/.ssh/id_rsa.pub)
DATA ?= $(CURDIR)
MODELS ?= $(HOME)
PORT ?= 8022
GTKPORT ?= 8085
# FIXME: map host to container UIDs so that logins will modify data on volumes with host UID not as root
run: $(DATA) $(MODELS)
	docker run --rm \
	-p $(PORT):22 \
	-p $(GTKPORT):8085 \
	--name ocrd_controller \
	-v $(DATA):/data \
	-v $(MODELS):/models \
	-e KEYS='$(KEYS)' \
	$(TAGNAME)

.PHONY: build run help
