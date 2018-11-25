FROM debian:stable-slim

# shell to start from Kitematic
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash

WORKDIR /root

ADD files/* /root/

# install software
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      nano \
      python3 \
      python3-pip \
      python3-setuptools \
      rsyslog \
      spamassassin \
      spamc \
      unzip \
      wget \
      python3-sphinx \
      lighttpd \
      logrotate \
      unattended-upgrades && \
    \
    \
# install dependencies for pushtest
    pip3 install  imapclient && \
    \
    \
# download and install isbg
	cd /root && \
    wget https://github.com/rsmuc/isbg/archive/rspamd.zip && \
    unzip rspamd.zip && \
    cd isbg-rspamd && \
    python3 setup.py install && \
    cd .. ; \
    rm -Rf /root/isbg-rspamd ; \
    rm /root/rspamd.zip ; \
    \
    \
############################
# configure software
############################

# create folders
    mkdir /root/accounts ; \
    cd /root && \
# fix permissions
    chown -R debian-spamd:mail /var/spamassassin ; \
# configure cron configuration
    crontab /root/cron_configuration && rm /root/cron_configuration ; \
# copy logrotate configuration
    mv mailreport_logrotate /etc/logrotate.d/mailreport_logrotate ; \
# configure spamassassin
    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/spamassassin ; \
    sed -i 's/CRON=0/CRON=1/' /etc/default/spamassassin ; \
    sed -i 's/^OPTIONS=".*"/OPTIONS="--allow-tell --max-children 5 --helper-home-dir -u debian-spamd -x --virtual-config-dir=\/var\/spamassassin -s mail"/' /etc/default/spamassassin ; \
    echo "bayes_path /var/spamassassin/bayesdb/bayes" >> /etc/spamassassin/local.cf ; \
    cp /root/spamassassin_user_prefs /etc/spamassassin/user_prefs.cf ;\
# configure OS base
    echo "alias logger='/usr/bin/logger -e'" >> /etc/bash.bashrc ; \
    echo "LANG=en_US.UTF-8" > /etc/default/locale ; \
    unlink /etc/localtime ; \
    ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime ; \
    unlink /etc/timezone ; \
    ln -s /usr/share/zoneinfo/Europe/Berlin /etc/timezone ; \
    \
    \
    \
# integrate geo database
    apt-get install -y --no-install-recommends cpanminus make wget&&\
	cpanm  YAML &&\
	cpanm Geography::Countries &&\
	cpanm Geo::IP IP::Country::Fast &&\
	cd /tmp && \
	wget -N http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz &&\
	gunzip GeoIP.dat.gz &&\
	mkdir /usr/local/share/GeoIP/ &&\
	mv GeoIP.dat /usr/local/share/GeoIP/ &&\
	echo "loadplugin Mail::SpamAssassin::Plugin::RelayCountry" >> /etc/spamassassin/init.pre ; \
	\
	# install rspamd
    CODENAME=`lsb_release -c -s` ;\
    echo "deb [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list ;\
    echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list ;\
    apt-get update ;\
    apt-get --no-install-recommends install -y --allow-unauthenticated rspamd redis-server ;\
    # configure rspamd
    echo "backend = 'redis'" > /etc/rspamd/local.d/classifier-bayes.conf ;\
    echo "new_schema = true;" >> /etc/rspamd/local.d/classifier-bayes.conf ;\
    echo "expire = 8640000;" >> /etc/rspamd/local.d/classifier-bayes.conf ;\
    echo "write_servers = 'localhost';" > /etc/rspamd/local.d/redis.conf ;\
    echo "read_servers = 'localhost';" >> /etc/rspamd/local.d/redis.conf ;\
    sed -i 's+/var/lib/redis+/var/spamassassin/bayesdb+' /etc/redis/redis.conf ;\

    \
# remove tools we don't need anymore
    apt-get remove -y wget python3-pip python3-setuptools unzip make cpanminus  && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# volumes
VOLUME /var/spamassassin/bayesdb
VOLUME /root/accounts

EXPOSE 80/tcp

CMD python3 /root/startup.py && tail -n 0 -F /var/log/*.log
