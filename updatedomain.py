#!/usr/bin/env python
"""Simple script to update DNS record with Rackspace CLoud DNS

Usage: python updatedomain.py fqdn newip

- The domain of the fqdn need to be already registered with Rackspace Cloud.

You need to have the python-clouddns package install from github :

http://github.com/rackspace/python-clouddns

You need to have the env varibale defined with :

US_RCLOUD_USER="foo"
US_RCLOUD_KEY="bar"

or for the UK Rackspace CLoud :

RCLOUD_REGION="UK"
UK_RCLOUD_USER="foo"
UK_RCLOUD_KEY="bar"
"""
import clouddns
import os
import sys

#Need to setup to your region
REGION = os.environ.get("RCLOUD_REGION", "US")

# Set via environ or directly here (US or UK depend of the region).
US_RCLOUD_USER = os.environ.get("US_RCLOUD_USER")
US_RCLOUD_KEY = os.environ.get("US_RCLOUD_KEY")

UK_RCLOUD_USER = os.environ.get("UK_RCLOUD_USER")
UK_RCLOUD_KEY = os.environ.get("UK_RCLOUD_KEY")

TTL = 300

if not US_RCLOUD_KEY or not US_RCLOUD_USER:
    print "API Keys env not defined"
    sys.exit(1)


class InvalidRegion(Exception):
    def __init__(self, region):
            self.region = region

    def __str__(self):
        return "InvalidRegion: %s" % repr(self.region)


def auth():
    if REGION.lower() == "us":
        return clouddns.connection.Connection(US_RCLOUD_USER, US_RCLOUD_KEY)
    elif REGION.lower() == "uk":
        return clouddns.connection.Connection(
            UK_RCLOUD_USER,
            UK_RCLOUD_KEY,
            authurl=clouddns.consts.uk_authurl)
    raise InvalidRegion(REGION)

args = sys.argv[1:]
if not args or len(args) < 2:
    print "%s: record newip" % (os.path.basename(sys.argv[0]))
    sys.exit(0)

chose_record = args[0]
ip = args[1]

cnx = auth()
all_domains = cnx.get_domains()
ourdomain = None
for domain in all_domains:
    if chose_record.endswith(domain.name):
        ourdomain = domain
        justrecord = chose_record.replace(domain.name, "")
        if justrecord.endswith('.'):
            justrecord = justrecord[:-1]

if not all((ourdomain, justrecord)):
    print "Cannot find our domain:"
    sys.exit(1)

all_records = ourdomain.get_records()
ourrecord = None
for record in all_records:
    if record.name == chose_record:
        ourrecord = record

if not ourrecord:
    print "creating new record: %s ip: %s" % (chose_record, ip)
    ourdomain.create_record(chose_record, ip, "A", TTL)
else:
    print "updating new record: %s ip: %s" % (chose_record, ip)
    ourrecord.update(data=ip)
