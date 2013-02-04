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
import argparse

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

parser = argparse.ArgumentParser()
parser.add_argument('-i', action='store_true', default=False,
                    dest='ipv6',
                    help='Use IPV6 record.')
parser.add_argument('record')
parser.add_argument('newip')
args = parser.parse_args()

record_type = args.ipv6 and "AAAA" or "A"

cnx = auth()
all_domains = cnx.get_domains()
ourdomain = None
for domain in all_domains:
    if args.record.endswith(domain.name):
        ourdomain = domain
        justrecord = args.record.replace(domain.name, "")
        if justrecord.endswith('.'):
            justrecord = justrecord[:-1]

if not all((ourdomain, justrecord)):
    print "Cannot find our domain:"
    sys.exit(1)

all_records = ourdomain.get_records()
ourrecord = None
for record in all_records:
    if record.name == args.record:
        ourrecord = record

if not ourrecord:
    print "creating new record: %s ip: %s" % (args.record, args.newip)
    ourdomain.create_record(args.record, args.newip, record_type, TTL)
else:
    print "updating new record: %s ip: %s" % (args.record, args.newip)
    ourrecord.update(data=args.newip)
