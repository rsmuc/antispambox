# antispambox

## Status

**not productive**

currently under development

## About

Antispambox is based on the idea of [IMAPScan](https://github.com/dc55028/imapscan). It's an Docker container including [ISBG](https://github.com/isbg/isbg). With ISBG it's possible to scan remotely an IMAP mailbox for SPAM mails and move them to a SPAM folder. So we are not dependent to the SPAM filter of our provider.

### Why not IMAPScan?

* The repository and code of IMAPScan does not include a license. So we don't know if I'm allowed to use and modify it.
* I prefer Python instead of Bash scripts

-> No code of IMAPScan is used in Antispambox.

### Why not ISBG? 

I made some modifications to ISBG and the push requests are still pending. In Antispambox currently my own fork of ISBG is used:

* I did not like that in ISBG every mail is processed twice by spamassassin.
* I wanted to have a report for every scanned email.


### Features

* Integrated a report for all HAM mails. Reachable via lighttpd e.g.: http://192.168.1.23:8000/mailreport.txt
* Integrated PUSH / IMAP IDLE support
* integrated geo database and filters for it
* focused on encrypted emails (header analysis only)
* custom spamassassin rules for Germany and header analysis (my mails are prefiltered by mailbox.org - this container is only focused to the SPAM the MBO filter does not catch)
* account information and bayes database persistent
* latest isbg + patched version

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

## License
GPLv3

see license text
