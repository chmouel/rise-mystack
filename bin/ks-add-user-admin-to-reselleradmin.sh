#!/bin/bash
set -e

cd ~/devstack/
eval $(for i in $(env|grep OS_);do echo -n "export ";echo -n ${i%%=*};echo =;done)
pushd ~/devstack > /dev/null && source openrc admin && popd > /dev/null

ADMIN_ID=$(keystone user-list|sed -n '/ admin / { s/^..//;s/ .*//; p}')
RESELLER_ID=$(keystone role-list|sed -n '/ ResellerAdmin / { s/^..//;s/ .*//; p}')
TENANT_ID=$(keystone tenant-list|sed -n '/ admin / { s/^..//;s/ .*//; p}')  

keystone user-role-add --user-id ${ADMIN_ID} --role-id ${RESELLER_ID} --tenant-id ${TENANT_ID}
keystone user-role-list --user-id ${ADMIN_ID} --tenant-id ${TENANT_ID}
