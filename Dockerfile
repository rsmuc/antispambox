FROM debian:stable-slim

# shell to start from Kitematic
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash

WORKDIR /root

COPY files/* /root/
COPY files/rspamd_config/* /root/rspamd_config/

# install software
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      nano \
      python3 \
      python3-pip \
      python3-setuptools \
      rsyslog \
      unzip \
      wget \
      python3-sphinx \
      lighttpd \
      logrotate \
      gnupg \
      unattended-upgrades && \


# install dependencies for pushtest
    pip3 install imapclient && \

# download and install irsd (as long as it is not pushed to pypi)
	cd /root && \
    wget https://codeberg.org/antispambox/IRSD/archive/master.zip && \
    unzip master.zip && \
    cd irsd && \
    python3 setup.py install && \
    cd .. ; \
    rm -Rf /root/irsd ; \
    rm /root/master.zip ; \

# install IP2Location
    pip3 install IP2Location && \
    wget https://download.ip2location.com/lite/IP2LOCATION-LITE-DB1.BIN.ZIP &&\
    wget https://download.ip2location.com/lite/IP2LOCATION-LITE-DB1.IPV6.BIN.ZIP &&\
    unzip -o IP2LOCATION-LITE-DB1.BIN.ZIP &&\
    unzip -o IP2LOCATION-LITE-DB1.IPV6.BIN.ZIP &&\
    rm *.ZIP &&\


############################
# configure software
############################

# create folders
    mkdir /root/accounts ; \
    cd /root && \

#
# configure cron configuration
    crontab /root/cron_configuration && rm /root/cron_configuration ; \
#
# copy logrotate configuration
    mv mailreport_logrotate /etc/logrotate.d/mailreport_logrotate ; \

# configure OS base
    echo "alias logger='/usr/bin/logger -e'" >> /etc/bash.bashrc ; \
    echo "LANG=en_US.UTF-8" > /etc/default/locale ; \
    unlink /etc/localtime ; \
    ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime ; \
    unlink /etc/timezone ; \
    ln -s /usr/share/zoneinfo/Europe/Berlin /etc/timezone ; \
#
# install rspamd
    CODENAME=`lsb_release -c -s` ;\
    echo "deb [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list ;\
    wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add ;\
    echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list ;\
    apt-get update ;\
    apt-get --no-install-recommends install -y --allow-unauthenticated rspamd redis-server ;\
    # configure rspamd
    #echo "backend = 'redis'" > /etc/rspamd/local.d/classifier-bayes.conf ;\
    #echo "new_schema = true;" >> /etc/rspamd/local.d/classifier-bayes.conf ;\
    #echo "expire = 8640000;" >> /etc/rspamd/local.d/classifier-bayes.conf ;\
    #echo "write_servers = 'localhost';" > /etc/rspamd/local.d/redis.conf ;\
    #echo "read_servers = 'localhost';" >> /etc/rspamd/local.d/redis.conf ;\
    sed -i 's+/var/lib/redis+/var/spamassassin/bayesdb+' /etc/redis/redis.conf ;\
    cp /root/rspamd_config/* /etc/rspamd/local.d/ ;\
    rm -r /root/rspamd_config ;\
#
# remove tools we don't need anymore
    apt-get remove -y wget python3-pip python3-setuptools unzip make cpanminus  && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# volumes
VOLUME /var/spamassassin/bayesdb
VOLUME /root/accounts

EXPOSE 11334/tcp

CMD python3 /root/startup.py && tail -n 0 -F /var/log/*.log
