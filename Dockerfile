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
      python \
      python-pip \
      python-setuptools \
      rsyslog \
      spamassassin \
      spamc \
      unzip \
      wget \
      python-sphinx \
      lighttpd \
      logrotate \
      unattended-upgrades && \
    \
    \
# install dependencies for isbg
    pip install sphinx_rtd_theme html recommonmark typing imapclient && \
    \
    \
# download and install isbg
	cd /root && \
    wget https://github.com/rsmuc/isbg/archive/all_in.zip && \
    unzip all_in.zip && \
    cd isbg-all_in && \
    python setup.py install && \
    cd .. ; \
    rm -Rf /root/isbg-all_in ; \
    rm /root/all_in.zip ; \
    \
    \
# download and install other files from antispambox (we could use ADD maybe in future)
    cd /root && \
    wget https://github.com/rsmuc/antispambox/archive/master.zip && \
    unzip master.zip && \
    cd antispambox-master/files && \
    cp * /root && \
    cd ; \
    rm -Rf /root/antispambox-master ; \
    rm /root/master.zip ; \
    \
    \
    \
############################
# configure software
############################

# create folders
    mkdir /root/accounts ; \
	mkdir /root/.spamassassin; \
	#mkdir -p /var/spamassassin/bayesdb ; \
	#cp /root/spamassassin_user_prefs /root/.spamassassin/user_prefs ;\
    cd /root && \
# fix permissions
    chown -R debian-spamd:mail /var/spamassassin ; \
    #chmod u+x startup ; \
    #chmod u+x *.sh ; \
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
    #echo "allow_user_rules 1" >> /etc/spamassassin/local.cf ; \
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
	\
    \
# remove tools we don't need anymore
    apt-get remove -y wget python-pip python-setuptools unzip make cpanminus  && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# volumes
VOLUME /var/spamassassin/bayesdb
VOLUME /root/accounts

EXPOSE 80/tcp

CMD python /root/startup.py && tail -n 0 -F /var/log/*.log
