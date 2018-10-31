# Open a connection in IDLE mode and wait for notifications from the
# server.

from imapclient import IMAPClient
import subprocess
import csv
import sys
import logging
from logging.handlers import TimedRotatingFileHandler
import datetime

# configure logging
logger = logging.getLogger("Pushtest")
logger.setLevel(logging.INFO)

# rotate the logfile everay 24 hours
handler = TimedRotatingFileHandler('/var/log/pushtest.log',
                                   when="H",
                                   interval=24,
                                   backupCount=5)

# format the logfile (add timestamp etc)
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s')

handler.setFormatter(formatter)
logger.addHandler(handler)


# read account information
try:
    account = list(csv.reader(open('/root/accounts/imap_accounts.txt', 'rb'), delimiter='\t'))
    HOST = account[1][0]
    USERNAME = account[1][1]
    PASSWORD = account[1][2]
    JUNK = account[1][3]
    INPUT = account[1][4]
    HAMTRAIN = account[1][5]
    SPAMTRAIN = account[1][6]
except IndexError:
    print ("ERROR: was not able to read imap_accounts.txt.")
    sys.exit(1)

def scan_spam():
    logger.info("Scanning for SPAM")
    p = subprocess.Popen(['/usr/local/bin/isbg', '--spamc', '--imaphost',
                          HOST, '--imapuser', USERNAME, '--imappasswd', PASSWORD,
                          '--spaminbox', JUNK, '--imapinbox', INPUT,
                          '--learnhambox', HAMTRAIN, '--learnspambox', SPAMTRAIN,
                          '--mailreport', '/var/www/html/mailreport.txt',
                          '--delete', '--expunge'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (output, err) = p.communicate()

def login():
    #login to server
    while True:
        try:
            server = IMAPClient(HOST)
            server.login(USERNAME, PASSWORD)
            server.select_folder('INBOX')
            # Start IDLE mode
            server.idle()
            logger.info("Connection is now in IDLE mode")
        except Exception as e:
            logger.info("Failed to connect - try again")
            logger.info(e.message)
            continue
        return server


def logoff(server):
    server.idle_done()
    logger.info(("\nIDLE mode done"))
    server.logout()

def pushing(server):
    """run IMAP idle until an exception (like no response) happens"""
    count = 0
    while True:
        try:
            # Wait for up to 30 seconds for an IDLE response
            responses = server.idle_check(timeout=29)           

            if responses:
                logger.info(responses)
                
            else:
                logger.info("Response: nothing")
                count = count + 1
             
            if count > 5:
                logger.info("No responses from Server - Scan for Spam, then Restart")
                scan_spam()
                count = 0
                raise Exception("No response")
            
            for response in responses:
                count = 0
                if response[1] == "RECENT" or response[1] == "EXISTS":
                    scan_spam()
            
                
        except KeyboardInterrupt:
            break
        except Exception as e:
            logger.info("Push error")
            count = 0
            logger.info(str(e.message))
            break

# run scan_spam once
scan_spam()

# run IMAP IDLE until CTRL-C is pressed.
while True:
    try:
        logger.info("Login to IMAP")
        server = login()
        logger.info("Start IAMP IDLE")
        pushing(server)
        logger.info("Logoff from IMAP")
        logoff(server)

    except KeyboardInterrupt:
        break
    except Exception as e:
        logger.info("Exception in Mainloop:")
        logger.info(str(e.message))

# logoff
logoff(server)
logger.info("Pushtest exited")

