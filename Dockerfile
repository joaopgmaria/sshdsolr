FROM alpine:latest

RUN apk update && \
	apk upgrade && \
	apk add openssh openjdk8 lsof sudo wget openrc bash

ENV SOLR_USER dev
ENV SOLR_PASS dev
ENV SOLR_GROUP dev
ENV SOLR_VERSION 6.6.1
ENV SOLR_PORT 8983
ENV SOLR_PATH /opt
ENV ZK_HOST zoo1:2181

RUN mkdir /home/$SOLR_USER && \
	addgroup -g 8000 $SOLR_GROUP && \
    adduser -S -u 8000 -h /home -G $SOLR_GROUP -s /bin/bash -D $SOLR_USER && \
	chown $SOLR_USER:$SOLR_GROUP /home/$SOLR_USER && \
	echo "$SOLR_USER:$SOLR_PASS" | chpasswd

# Openrc related
RUN openrc && \
	touch /run/openrc/softlevel

RUN mkdir /var/run/sshd && \
	sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	mkdir /home/$SOLR_USER/.ssh

# SSH login fix. Otherwise user is kicked off after login
#RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN echo "$SOLR_USER ALL=NOPASSWD: ALL" >> /etc/sudoers

COPY install_solr.sh .
RUN chmod +x ./install_solr.sh
RUN ./install_solr.sh
	
EXPOSE $SOLR_PORT
EXPOSE 22

WORKDIR /home/$SOLR_USER
USER $SOLR_USER

CMD sudo service solr start && sudo service sshd restart && sleep 10 && /bin/bash
