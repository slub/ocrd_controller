# cf. github.com/OCR-D/ocrd_all
# ocrd/all # ocrd/core # ubuntu:18.04
ARG VERSION=maximum-git
# maximum-cuda-git
FROM ocrd/all:$VERSION

MAINTAINER robert.sachunsky@slub-dresden.de
ARG VCS_REF
ARG BUILD_DATE
LABEL \
    maintainer="https://slub-dresden.de" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/slub/ocrd_controller" \
    org.label-schema.build-date=$BUILD_DATE

# keep PREFIX and VIRTUAL_ENV from ocrd/all (i.e. /usr/local)
# but export them for COPY etc
ENV PREFIX=$PREFIX
ENV VIRTUAL_ENV=$VIRTUAL_ENV
ENV HOME=/

# must mount a host-side directory for ocrd-resources
VOLUME /models
# override XDG_DATA_HOME from ocrd/all (i.e. /usr/local/share)
ENV XDG_DATA_HOME=/models
# override TESSDATA_PREFIX from ocrd/all
ENV TESSDATA_PREFIX=$XDG_DATA_HOME/ocrd-resources/ocrd-tesserocr-recognize
# must mount a host-side directory for ocrd/resource.yml
VOLUME /config
ENV XDG_CONFIG_HOME=/config
# enable caching of METS structures in processors
ENV OCRD_METS_CACHING=true

# make apt run non-interactive during build
ENV DEBIAN_FRONTEND noninteractive

# make apt system functional
RUN apt-get update && \
    apt-get install -y apt-utils wget git openssh-server rsyslog rsync  && \
    apt-get clean

# run OpenSSH server
RUN ssh-keygen -A
RUN mkdir /run/sshd /.ssh
RUN echo Banner none >> /etc/ssh/sshd_config
RUN echo PrintMotd no >> /etc/ssh/sshd_config
RUN echo PermitUserEnvironment yes >> /etc/ssh/sshd_config
RUN echo PermitUserRC yes >> /etc/ssh/sshd_config
RUN echo X11Forwarding no >> /etc/ssh/sshd_config
RUN echo AllowUsers ocrd admin >> /etc/ssh/sshd_config
# chdir to the data volume (so relative paths work as expected)
RUN echo "cd /data" >> /etc/profile
RUN echo 'umask $UMASK' >> /etc/profile
RUN /usr/sbin/sshd -t
COPY start-sshd.sh /usr/bin/
CMD ["/usr/bin/start-sshd.sh"]
EXPOSE 22

WORKDIR /build

RUN ln /usr/bin/python3 /usr/bin/python
# configure writing to ocrd.log for profiling
COPY ocrd_logging.conf /etc

# make apt run interactive during logins
ENV DEBIAN_FRONTEND teletype

WORKDIR /data
VOLUME /data
