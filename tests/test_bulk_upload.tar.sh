#!/bin/bash

eval $(ks -s)

mkdir -p /tmp/tarball/{foo,bar}
echo $RANDOM > /tmp/tarball/foo/a.txt
echo $RANDOM > /tmp/tarball/bar/b.txt
cd /tmp/tarball
tar -cf /tmp/example.tar *

curl -H "x-auth-token: ${TOKEN}" -i -X PUT ${STORAGE_URL}/?extract-archive=tar --data-binary @/tmp/example.tar
