# cf. github.com/OCR-D/ocrd_all
# ocrd/all # ocrd/core # ubuntu:18.04
ARG VERSION=maximum-git
# maximum-cuda-git
FROM ocrd/all:$VERSION

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

MAINTAINER robert.sachunsky@slub-dresden.de
LABEL maintainer="https://slub-dresden.de"
LABEL org.label-schema.vendor="Saxon State and University Library Dresden"
LABEL org.label-schema.name="OCR-D Controller"
LABEL org.label-schema.vcs-url="https://github.com/slub/ocrd_controller"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.opencontainers.image.vendor="Saxon State and University Library Dresden"
LABEL org.opencontainers.image.title="OCR-D Controller"
LABEL org.opencontainers.image.description="Path to network implementation of OCR-D"
LABEL org.opencontainers.image.source="https://github.com/slub/ocrd_controller"
LABEL org.opencontainers.image.documentation="https://github.com/slub/ocrd_controller/blob/${VCS_REF}/README.md"
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.base.name=ocrd/all:$VERSION

# keep PREFIX and VIRTUAL_ENV from ocrd/all (i.e. /usr/local)
# but export them for COPY etc
ENV PREFIX=$PREFIX
ENV VIRTUAL_ENV=$VIRTUAL_ENV
ENV HOME=/

# must mount a host-side directory for ocrd-resources
VOLUME /models
# ensure volume can be written by any user
RUN chmod go+rwx /models
# override XDG_DATA_HOME from ocrd/all (i.e. /usr/local/share)
ENV XDG_DATA_HOME=/models
# override TESSDATA_PREFIX from ocrd/all
ENV TESSDATA_PREFIX=$XDG_DATA_HOME/ocrd-resources/ocrd-tesserocr-recognize
# enable caching of METS structures in processors
ENV OCRD_METS_CACHING=1

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
