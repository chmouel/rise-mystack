#!/bin/bash

sed -i 's/^token_format = PKI/token_format = UUID/' /etc/keystone/keystone.conf

