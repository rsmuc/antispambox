import os
from shutil import copyfile
import subprocess
import json
import sys


def cleanup_file(filename):
    """If file exists, delete it"""
    if os.path.isfile(filename):
        os.remove(filename)
    else:  ## Show an error ##
        print("%s does not exist" % filename)


def copy_file_if_not_exists(src, dest):
    """Copy the file if it does not exist at the destination"""
    if os.path.isfile(dest):
        print("%s does already exist - do nothing" % dest)
    else:
        copyfile(src, dest)
        print("%s copied" % dest)


def start_service(servicename):
    """Start a Linux service"""
    print("startup service %s" % servicename)
    p = subprocess.Popen(['/usr/sbin/service', servicename, 'start'], stdout=subprocess.PIPE)
    p.communicate()
    if p.returncode != 0:
        print("startup of service %s failed" % servicename)


def check_imap_configuration():
    """ check if the IMAP account has already been configured"""

    try:
        with open("/root/accounts/imap_accounts.json", 'r') as f:
            datastore = json.load(f)
        enabled = datastore["antispambox"]["enabled"]
        host = datastore["antispambox"]["account"]["server"]

    except IndexError:
        print("ERROR: was not able to read imap_accounts.json.")
        sys.exit()

    if enabled != "True":
        print("ERROR: Antispambox configuration is not set to enabled - end the service")
        sys.exit()

    if host == "imap.example.net":
        print("ERROR: no accounts in imap_accounts.json configured - please configure and restart")
        sys.exit()


def fix_permissions():
    """ fix the permissions of the bayes folders"""
    p = subprocess.Popen(['chown', '-R', 'debian-spamd:mail', '/var/spamassassin'], stdout=subprocess.PIPE)
    (output, err) = p.communicate()
    if p.returncode != 0:
        print("chown failed")
        print(err)
        print(output)
    p = subprocess.Popen(['chmod', 'a+wr', '/var/spamassassin', '-R'], stdout=subprocess.PIPE)
    (output, err) = p.communicate()
    if p.returncode != 0:
        print("chmod failed")
        print(err)
        print(output)


def download_spamassassin_rules():
    """download the spamassassin rules"""
    p = subprocess.Popen(['/usr/bin/sa-update', '--no-gpg', '-v', '--channelfile', '/root/sa-channels'],
                         stdout=subprocess.PIPE)
    (output, err) = p.communicate()
    if p.returncode != 0 and p.returncode != 1:
        print("ERROR: sa-update failed")
        print(err)
        print(output)

    p = subprocess.Popen(['/usr/bin/sa-update', '--no-gpg', '-v'], stdout=subprocess.PIPE)
    (output, err) = p.communicate()
    if p.returncode != 0 and p.returncode != 1:
        print("ERROR: sa-update failed")
        print(err)
        print(output)


def start_imap_idle():
    p = subprocess.Popen(['python3', '/root/antispambox.py'], stdout=subprocess.PIPE)
    (output, err) = p.communicate()
    # this will usually run endless
    if p.returncode != 0:
        print("ERROR: IMAPIDLE / PUSH / antispambox failed")
        print(err)
        print(output)


print("\n\n\n ******* STARTUP ANTISPAMBOX ******* \n\n\n")

print("\n\n *** delete lock files if still existing")
cleanup_file("/var/spamassassin/scan_lock")
cleanup_file("/root/.cache/isbg/lock")

print("\n\n *** copy imap_accounts.json file")
copy_file_if_not_exists("/root/imap_accounts.json", "/root/accounts/imap_accounts.json")

print("\n\n *** fixing permissions")
fix_permissions()

print("\n\n *** updating spamassassin rules")
download_spamassassin_rules()

print("\n\n *** start the services")
start_service("rsyslog")
start_service("redis-server")
start_service("rspamd")
start_service("spamassassin")
start_service("lighttpd")
start_service("cron")

print("\n\n *** check if the imap account configuration is available and active")
check_imap_configuration()

print("\n\n *** start of IMAPIDLE / PUSH")
start_imap_idle()
