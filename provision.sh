#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get -y upgrade
    

    apt-get install bind9 bind9utils bind9-doc -y
    cp /vagrant/archivos/named /etc/default/

    cp /vagrant/archivos/resolv.conf /etc/

    if [ $(cat /etc/hostname) == 'tierra' ]; then
        cp /vagrant/archivos/tierra/named.conf.options /etc/bind/
        cp /vagrant/archivos/tierra/named.conf.local /etc/bind/
        cp /vagrant/archivos/tierra/sistema.sol.dns /vagrant/archivos/tierra/sistema.sol.rev.rev /var/lib/bind/
    else 
     
        cp /vagrant/archivos/venus/named.conf.options /etc/bind/
        cp /vagrant/archivos/venus/named.conf.local /etc/bind/
    fi

    systemctl restart named   


unset DEBIAN_FRONTEND