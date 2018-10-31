# antispambox

## Status

**under development**

container should be working basically

## About

Antispambox is based on the idea of [IMAPScan](https://github.com/dc55028/imapscan). It's an Docker container including [ISBG](https://github.com/isbg/isbg). With ISBG it's possible to scan remotely an IMAP mailbox for SPAM mails and move them to a SPAM folder. So we are not dependent to the SPAM filter of our provider.

### Why not IMAPScan?

(Thanks to [dc55028](https://github.com/dc55028) for adding the MIT license to the IMAPScan repository)

* I prefer Python instead of Bash scripts
* I made several modifications (see Features) and not all of the modifications would be compatible to the ideas of IMAPScan


### Why not ISBG? 

I made some modifications to ISBG and the push requests are still pending. In Antispambox currently my own fork of ISBG is used:

* I did not like that in ISBG every mail is processed twice by spamassassin.
* I wanted to have a report for every scanned email.


### Features

* Integrated a report for all HAM mails. Reachable via lighttpd e.g.: http://192.168.1.23:8000/mailreport.txt
* Integrated PUSH / IMAP IDLE support
* integrated geo database and filters for it
* focused on encrypted emails (header analysis only)
* **custom spamassassin rules for Germany and header analysis (my mails are prefiltered by mailbox.org - this container is only focused to the SPAM the MBO filter does not catch)**
* account settings and bayes database is persistent
* latest isbg + patched version
* Small footprint

## Using the container

### building the container
* ```docker build -f Dockerfile -t antispambox . --no-cache```

### starting the container

* ```sudo docker volume create bayesdb```
* ```sudo docker volume create accounts```
* ```sudo docker run -d --name antispambox -v bayesdb:/var/spamassassin/bayesdb -v accounts:/root/accounts -p 8000:80 antispambox```

### configure the container

* if available copy a backup of your bayes_database to the container and use sa-learn --restore
* configure the account at /root/accounts
* reboot the container

## TODOs

* don't use tabs in configuration file. maybe switch to json or xml
* Move custom rules to own channel or seperate from users_conf(https://wiki.apache.org/spamassassin/PublishingRuleUpdates)
* don't save the password in text file
* fix logging of startup.py
* get rid of python2

## License
MIT

see license text
