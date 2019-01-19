# antispambox

## Status

**under development**

container should be working basically

## About

Antispambox is based on the idea of [IMAPScan](https://github.com/dc55028/imapscan). It's an Docker container including [ISBG](https://github.com/isbg/isbg). With ISBG it's possible to scan remotely an IMAP mailbox for SPAM mails with spamassassin. So we are not dependent to the SPAM filter of our provider.

Antispambox does have two anti-spam-engines integrated. Spamassassin and RSpamd.

### Why not IMAPScan?

(Thanks to [dc55028](https://github.com/dc55028) for adding the MIT license to the IMAPScan repository)

* I prefer Python instead of Bash scripts
* I made several modifications (see Features) and not all of the modifications would be compatible to the ideas of IMAPScan
* I integrated push support
* ...

### Why not ISBG only?

ISBG is only supporting spamassassin as backend. Spamassassin is a very effective, but not very efficient SPAM filter. At home I'm running the docker container on a very small embedded PC with an Atom CPU. On my smartphone I'm using K9Mail with push support. So it is very important that the scanning for SPAM is very fast. With spamassassin it takes too long to filter the mails, so SPAM mails are shown on my smartphone before they are filterd out. The solution: rspamd. 

But rspamd is not supported by ISBG and will not be supported to keep ISBG maintainable. So I forked ISBG and created IRSD. 

Antispambox integrated both.

### Why not IRSD only?

rspamd scans the mails on my machine very fast and efficient but the detection rate is not as good for me as spamassassin. 

### Features

* Integration of ISBG (spamassassin)
* Integration of IRSD (rspamd)
* Integrated PUSH / IMAP IDLE support
* integrated geo database and filters for it
* focused on encrypted emails (header analysis only)
* **custom spamassassin rules for Germany and header analysis (my mails are prefiltered by mailbox.org - this container is only focused to the SPAM the MBO filter does not catch) - so the rules may not match your requirements**
* In future: Webinterface to configure everything
* In future: Configure the rspamd webinterface
* In future: Support multiple IMAP accounts within one container

## Using the container

### building the container

* ```docker build -f Dockerfile -t antispambox . --no-cache```

### starting the container

* ```sudo docker volume create bayesdb```
* ```sudo docker volume create accounts```

  ```
* ```sudo docker run -d --name antispambox -v bayesdb:/var/spamassassin/bayesdb -v accounts:/root/accounts antispambox```

### workflow and configuration

* To configure the container run:
  * `docker exec -i -t antispambox /bin/bash`
  * use nano to configure the /root/accounts/imap_accounts.json
* startup.py will be directly started with the docker container. To enable the scanning for spam, you need to set in /accounts/imap_accounts.json the enabled flag to true. By deafult this flag will be set to false until the configuration is finished. 
* First configure you maril account in /root/accounts/imap_accounts.json
* Train spamassassinn and spamd:
  * To ensure that spamassassin and spamd bayes filtering is working you should train it at least with 200 SPAM and 200 HAM mails. 

    To train the filter copy your SPAM and HAM messages in the IMAP folders you configured for SPAM_learn and HAM_learn and execute /root/train_only.py
* Set the enabled flag in /root/accounts/imap_accounts.json to true.
* Restart the docker container
* The docker container will not start with IMAP idle to your INBOX folder and check for new mails. If a SPAM mail is detected, Antispambox will move the SPAM to your JUNK folder.
* If a SPAM mail is not detect by Antispambox move the SPAM to your SPAM_train folder. If a HAM mail is detected as SPAM, move the mail to HAM_train. The backend services spamassassin and rspamd will learn improve their detection rate.

## TODOs

* see features
* PEP8 & static code analysis

## License

MIT

see license text
