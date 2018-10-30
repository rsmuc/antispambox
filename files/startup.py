import os
from shutil import copyfile
import subprocess
import csv

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

print("startup antispambox")

print("delete lock files if still existing")
cleanup_file("/var/spamassassin/scan_lock")
cleanup_file("/root/.cache/isbg/lock")

print("copy imap_accounts.txt files")
copy_file_if_not_exists("/root/imap_accounts.txt", "/root/accounts/imap_accounts.txt")

print("start the services")
start_service("rsyslog")

print("fixing permissions")
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


print("updating spamassassin rules")
p = subprocess.Popen(['/usr/bin/sa-update', '--no-gpg', '-v', '--channelfile', '/root/sa-channels'], stdout=subprocess.PIPE)
(output, err) = p.communicate()
p = subprocess.Popen(['/usr/bin/sa-update', '--no-gpg', '-v'], stdout=subprocess.PIPE)
(output, err) = p.communicate()


start_service("spamassassin")
start_service("lighttpd")
start_service("cron")

print("check if the imap account configuration is available")
account = list(csv.reader(open('/root/accounts/imap_accounts.txt', 'rb'), delimiter='\t'))
HOST = account[1][0]
if HOST == "imap.example.net":
    print("ERROR: no accounts in imap_accounts.txt configured - please configure and restart")

else:
    print ("start von pushtest")
    p = subprocess.Popen(['python', '/root/pushtest.py'], stdout=subprocess.PIPE)
    (output, err) = p.communicate()
    # this will usually run endless
    if p.returncode != 0:
        print("ERROR: pushtest failed")
        print(err)
        print(output)