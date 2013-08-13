#!/bin/bash


echo $RANDOM > /tmp/a.txt
echo $RANDOM > /tmp/b.txt

eval $(ks -s localhost demo:demo ADMIN)

swift post testbulk >/dev/null
swift upload testbulk /tmp/{a,b}.txt >/dev/null

curl -i -H 'Content-Type: text/plain' -H "x-auth-token: ${TOKEN}" -X DELETE ${STORAGE_URL}/testbulk\?bulk-delete -d 'testbulk/tmp/a.txt'
