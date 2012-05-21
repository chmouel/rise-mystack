# Swift Tools
set -e
function get_id () {
    echo `"$@" | awk '/ id / { print $4 }'`
}

#Roles
ADMIN_ROLE=$(keystone role-list|awk '/admin/ {print $2}')
ANOTHER_ROLE=$(keystone role-list|awk '/anotherrole/ {print $2}')

# Primary functional test account (needs admin access to the account)
TENANT1=$(get_id keystone tenant-create --name=test)
USER1=$(get_id keystone user-create --name=tester \
              --pass=testing \
              --email=test@example.com)
keystone user-role-add --user_id $USER1 --role_id $ADMIN_ROLE --tenant_id $TENANT1

# User on a second account (needs admin access to the account)
TENANT2=$(get_id keystone tenant-create --name=test2)
USER2=$(get_id keystone user-create --name=tester2 \
              --pass=testing2 \
              --email=test2@example.com)
keystone user-role-add --user_id $USER2 --role_id $ADMIN_ROLE --tenant_id $TENANT2

# User on same account as first, but without admin access
USER3=$(get_id keystone user-create --name=tester3 \
              --pass=testing3 \
              --email=test3@example.com)
keystone user-role-add --user_id $USER3 --role_id $ADMIN_ROLE --tenant_id $TENANT1

mkdir -p /etc/swift
cat <<EOF>/etc/swift/test.conf
[func_test]
auth_host = 127.0.0.1
auth_port = 35357
auth_ssl = no
auth_prefix = /v2.0/
auth_version = 2

# Primary functional test account (needs admin access to the account)
account = test
username = tester
password = testing

# User on a second account (needs admin access to the account)
account2 = test2
username2 = tester2
password2 = testing2

# User on same account as first, but without admin access
username3 = tester3
password3 = testing3

collate = C

[unit_test]
fake_syslog = False
EOF
