FROM ubuntu:16.04
MAINTAINER Joao Maria <joao.maria@sky.uk>

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

RUN wget -q http://apache.mirror.anlx.net/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz && \
	tar xzf ./solr-$SOLR_VERSION.tgz solr-$SOLR_VERSION/bin/install_solr_service.sh --strip-components=2 && \
	./install_solr_service.sh solr-$SOLR_VERSION.tgz -i $SOLR_PATH -n && \
	echo ZK_HOST=$ZK_HOST >> /etc/default/solr.in.sh && \
	chmod +x /opt/solr/server/scripts/cloud-scripts/zkcli.sh && \
	rm -fv /solr-$SOLR_VERSION.tgz
	
EXPOSE $SOLR_PORT
EXPOSE 22

WORKDIR /home/$SOLR_USER
USER $SOLR_USER

CMD sudo service solr start && sudo service ssh restart && sleep 10 && /bin/bash
