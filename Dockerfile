# cf. github.com/OCR-D/ocrd_all
# ocrd/all # ocrd/core # ubuntu:18.04
ARG VERSION=maximum-git
# maximum-cuda-git
FROM ocrd/all:$VERSION

MAINTAINER robert.sachunsky@slub-dresden.de

# keep PREFIX and VIRTUAL_ENV from ocrd/all
# but export them for COPY etc
ENV PREFIX=$PREFIX
ENV VIRTUAL_ENV=$VIRTUAL_ENV
ENV HOME=/

# must mount a host-side directory for models
VOLUME /models
ENV XDG_DATA_HOME=/models
ENV XDG_CONFIG_HOME=/models
ENV TESSDATA_PREFIX=$XDG_DATA_HOME/ocrd-resources/ocrd-tesserocr-recognize

# make apt run non-interactive during build
ENV DEBIAN_FRONTEND noninteractive

# make apt system functional
RUN apt-get update && \
    apt-get install -y apt-utils wget git openssh-server  && \
    apt-get clean

# run OpenSSH server
RUN echo "for root login only" > /etc/nologin
# default sshd_config#PermitRootLogin is prohibit-password
# so we only need to bind-mount root's ~/.ssh/authorized_keys file:
# --mount type=bind,source=...,destination=/.ssh/authorized_keys
RUN ssh-keygen -A
RUN mkdir /run/sshd /root/.ssh
RUN echo Banner none >> /etc/ssh/sshd_config
RUN echo PrintMotd no >> /etc/ssh/sshd_config
RUN echo PermitUserEnvironment yes >> /etc/ssh/sshd_config
RUN echo PermitUserRC yes >> /etc/ssh/sshd_config
RUN echo "cd /data" >> /etc/profile
RUN /usr/sbin/sshd -t
COPY start-sshd.sh /usr/bin
CMD ["/usr/bin/start-sshd.sh"]
EXPOSE 22

WORKDIR /build

RUN ln /usr/bin/python3 /usr/bin/python
# prevent make from updating the git modules automatically
ENV NO_UPDATE=1
# update to sbb_binarization#31 (setup during init)
RUN git -C sbb_binarization fetch origin pull/31/head:setup-init
RUN git -C sbb_binarization checkout setup-init
RUN make -W sbb_binarization ocrd-sbb-binarize
# update to core#652 (workflow server)
RUN git -C core fetch origin pull/652/head:workflow-server
RUN git -C core checkout workflow-server
RUN make -C core install PIP_INSTALL="pip install -e"
RUN for venv in /usr/local/sub-venv/*; do source $venv/bin/activate && make -C core install PIP_INSTALL="pip install -e"; done
# configure writing to ocrd.log for profiling
COPY ocrd_logging.conf /etc

# add ocrd_browser via Broadway HTTP bridge
COPY ocrd-browser $PREFIX/bin/ocrd-browser
RUN git clone https://github.com/hnesk/browse-ocrd
RUN make -C browse-ocrd deps-ubuntu
RUN pip install --ignore-installed -U PyGObject
RUN make -C browse-ocrd deps
RUN pip install -e browse-ocrd
RUN apt-get install -y libgtk-3-bin
ENV GDK_BACKEND broadway
ENV BROADWAY_DISPLAY :5
EXPOSE 8085

# make apt run interactive during logins
ENV DEBIAN_FRONTEND teletype

WORKDIR /data
VOLUME /data
