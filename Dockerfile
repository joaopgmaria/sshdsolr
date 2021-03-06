FROM ubuntu:16.04

RUN apt-get update && apt-get install -y openssh-server openjdk-8-jdk lsof sudo nano

ENV SOLR_USER dev
ENV SOLR_PASS dev
ENV SOLR_GROUP dev
ENV SOLR_VERSION 6.6.1
ENV SOLR_PORT 8983
ENV SOLR_PATH /opt
ENV ZK_HOST zoo1:2181

RUN mkdir /home/$SOLR_USER && \
	addgroup -system -gid 8000 $SOLR_GROUP && \
    useradd -u 8000 -b /home -g $SOLR_GROUP $SOLR_USER && \
	chown $SOLR_USER:$SOLR_GROUP /home/$SOLR_USER && \
	echo "$SOLR_USER:$SOLR_PASS" | chpasswd

RUN mkdir /var/run/sshd && \
	sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	mkdir /home/$SOLR_USER/.ssh

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN echo "$SOLR_USER ALL=NOPASSWD: ALL" >> /etc/sudoers

#Change default shell to bash for user and root
RUN chsh -s /bin/bash $SOLR_USER
RUN chsh -s /bin/bash root

RUN wget -q http://archive.apache.org/dist/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz && \
	tar xzf ./solr-$SOLR_VERSION.tgz solr-$SOLR_VERSION/bin/install_solr_service.sh --strip-components=2 && \
	./install_solr_service.sh solr-$SOLR_VERSION.tgz -i $SOLR_PATH -n -p $SOLR_PORT -u $SOLR_USER && \
	chmod +x /opt/solr/server/scripts/cloud-scripts/zkcli.sh && \
	rm -fv /solr-$SOLR_VERSION.tgz
	
EXPOSE $SOLR_PORT
EXPOSE 22

COPY ./prepare_solr.sh /home/$SOLR_USER
RUN chmod +x /home/$SOLR_USER/prepare_solr.sh

WORKDIR /home/$SOLR_USER
USER $SOLR_USER

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="SSHDSOLR" \
      org.label-schema.description="Docker container running SOLR and SSHD" \
      org.label-schema.url="https://hub.docker.com/r/jpmaria/sshdsolr" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/joaopgmaria/sshdsolr" \
      org.label-schema.vendor="jpmaria" \
      org.label-schema.schema-version="1.0"

CMD ./prepare_solr.sh && sudo service solr start && sudo service ssh restart && sleep 10 && /bin/bash
