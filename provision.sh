#!/bin/bash
apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

apt-get -y install bind9

cp -v /vagrant/named.conf.options /etc/bind

systemctl restart bind9