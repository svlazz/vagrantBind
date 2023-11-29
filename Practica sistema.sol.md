### Creamos la máquina virtual de tierra.sistema.sol
Configuramos las dos interfaces red:
- NAT para salir a internet
- Interna: Para la práctica
Instalamos el sistema operativo (Debian):
- Hacemos un nano a /etc/network/interfaces y configuramos la nueva interfaz de red (enp0s8) con la IP 192.168.57.103
```
auto enp0s8
iface enp0s8 inet static
address 192.168.57.103
network 192.168.57.0
netmask 255.255.255.0
```
Configuracion bind:
- Instalamos bind con el comando:
`apt install bind9 bind9utils bind9-utils`
- Nos vamos al archivo /etc/resolv.conf y ponemos: `nameservers 192.168.57.103`
- Configuramos el archivo /etc/bind/named.conf.options:
```

acl permitidos {
        192.168.57.0/24;
        localnets;
        localhost;
};

options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

        forwarders {
                208.67.222.222;
        };

        //=====================================================================>
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //=====================================================================>
        dnssec-validation yes;
        allow-transfer { 192.168.57.102; };
        //listen-on-v6 { any; };
        allow-recursion { permitidos; };
        listen-on port 53 { 192.168.57.103; };
};

```
- Configuramos las zonas en el fichero /etc/bind/named.conf.local:
``` conf
zone "sistema.sol" {
	type master;
	file "/var/lib/bind/sistema.sol.dns"
};
zone "57.168.192.in-addr.arpa" {
	type master;
	file "/var/lib/bind/sistema.sol.rev";
};
```
- Configuramos la zona directa:
```conf
$TTL 86400
@   IN  SOA  tierra.sistema.sol. root.tierra.sistema.sol. (
		1 ; Serial
		604800 ; Refresh
		86400 ; Retry
		2419200 ; Expire
		7200 ) ; Negative Cache TL
;
@  IN  NS  tierra.sistema.sol.
tierra.sistema.sol. IN A 192.168.57.103
ns1 IN CNAME tierra.sistema.sol.
venus.sistema.sol. IN  A 192.168.57.102
ns2 IN CNAME venus.sistema.sol.
marte.sistema.sol. IN A 192.168.57.104
mail IN CNAME marte.sistema.sol.
@    IN MX 10 marte.sistema.sol.
```

- Reverse zone:
```
$TTL 86400
@   IN  SOA  tierra.sistema.sol. root.tierra.sistema.sol. (
		1 ; Serial
		604800 ; Refresh
		86400 ; Retry
		2419200 ; Expire
		7200 ) ; Negative Cache TL
;
@  IN  NS  tierra.sistema.sol.
103 IN PTR tierra.sistema.sol.
102 IN PTR venus.sistema.sol.
104 IN PTR marte.sistema.sol.
```

### Creamos la máquina virtual de venus.sistema.sol
En este caso esta máquina va a ser el servidor DNS esclavo.
- Configuramos la IP estática (/etc/network/interfaces):
```
auto enp0s8
iface enp0s8 inet static
address 192.168.57.102
network 192.168.57.0
netmask 255.255.255.0
```
- Instalamos bind: `apt install bind9 bind9utils bind9-utils`
- - Nos vamos al archivo /etc/resolv.conf y ponemos: `nameservers 192.168.57.102`
- Configuramos el archivo /etc/bind/named.conf.options
```
acl permitidos {
        192.168.57.0/24;
        localhost;
        localnets;
};
options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

        forwarders {
                208.67.222.222;
        };

        //=====================================================================>
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //=====================================================================>
        dnssec-validation yes;
        listen-on port 53 { 192.168.57.102; };
        //listen-on-v6 { any; };
        allow-recursion { permitidos; };
};

```
- Configuramos el archivo /etc/bind/named.conf.local
```
zone "sistema.sol" {
        type slave;
        file "/var/lib/bind/sistema.sol.dns";
        masters {
                192.168.57.103;
        };
};

zone "57.168.192.in-addr.arpa" {
        type slave;
        file "/var/lib/bind/sistema.sol.rev";
        masters {
                192.168.57.103;
        };
};
```

### Comprobacion

Desde venus.sistema.sol hacemos un dig a tierra.sistema.sol y a marte.sistema.sol
Resultado `dig tierra.sistema.sol`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> tierra.sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 2147
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: a22f85d57bb935b601000000655e368c58121cffca6256de (good)
;; QUESTION SECTION:
;tierra.sistema.sol.            IN      A

;; ANSWER SECTION:
tierra.sistema.sol.     86400   IN      A       192.168.57.103

;; Query time: 0 msec
;; SERVER: 192.168.57.102#53(192.168.57.102) (UDP)
;; WHEN: Wed Nov 22 18:12:44 CET 2023
;; MSG SIZE  rcvd: 91

```
Resultado `dig -x 192.168.57.103`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> -x 192.168.57.103
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 61733
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 9e888c245f7632f701000000655e37581f64a5de0d99d45d (good)
;; QUESTION SECTION:
;103.57.168.192.in-addr.arpa.   IN      PTR

;; ANSWER SECTION:
103.57.168.192.in-addr.arpa. 86400 IN   PTR     tierra.sistema.sol.

;; Query time: 0 msec
;; SERVER: 192.168.57.102#53(192.168.57.102) (UDP)
;; WHEN: Wed Nov 22 18:16:08 CET 2023
;; MSG SIZE  rcvd: 116

```

Resultado `dig marte.sistema.sol`
```


; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> marte.sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 21921
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: b9f9408d7ba0f31b01000000655e369bb680d0dba2e74760 (good)
;; QUESTION SECTION:
;marte.sistema.sol.             IN      A

;; ANSWER SECTION:
marte.sistema.sol.      86400   IN      A       192.168.57.104

;; Query time: 0 msec
;; SERVER: 192.168.57.102#53(192.168.57.102) (UDP)
;; WHEN: Wed Nov 22 18:12:59 CET 2023
;; MSG SIZE  rcvd: 90

```

Resultado `dig -x 192.168.57.104`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> -x 192.168.57.104
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 28802
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: cd22ca18aaca6e9101000000655e378cbbdc2f361839a084 (good)
;; QUESTION SECTION:
;104.57.168.192.in-addr.arpa.   IN      PTR

;; ANSWER SECTION:
104.57.168.192.in-addr.arpa. 86400 IN   PTR     marte.sistema.sol.

;; Query time: 0 msec
;; SERVER: 192.168.57.102#53(192.168.57.102) (UDP)
;; WHEN: Wed Nov 22 18:17:00 CET 2023
;; MSG SIZE  rcvd: 115

```

Resultado `dig venus.sistema.sol`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> venus.sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 55523
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: f91dcd548607a01901000000655e37ee956c12c20cd98871 (good)
;; QUESTION SECTION:
;venus.sistema.sol.             IN      A

;; ANSWER SECTION:
venus.sistema.sol.      86400   IN      A       192.168.57.102

;; Query time: 0 msec
;; SERVER: 192.168.57.103#53(192.168.57.103) (UDP)
;; WHEN: Wed Nov 22 18:18:38 CET 2023
;; MSG SIZE  rcvd: 90

```

Resultado `dig -x 192.168.57.102`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> -x 192.168.57.102
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 24786
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 83d8dae054dcf1d701000000655e3808c6092dad1063feb5 (good)
;; QUESTION SECTION:
;102.57.168.192.in-addr.arpa.   IN      PTR

;; ANSWER SECTION:
102.57.168.192.in-addr.arpa. 86400 IN   PTR     venus.sistema.sol.

;; Query time: 0 msec
;; SERVER: 192.168.57.103#53(192.168.57.103) (UDP)
;; WHEN: Wed Nov 22 18:19:04 CET 2023
;; MSG SIZE  rcvd: 115
```

Resultado `dig ns1.sistema.sol`
```

; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> ns1.sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 65280
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: c4480af2679cc18101000000655e37afaecb3198d9ba97ce (good)
;; QUESTION SECTION:
;ns1.sistema.sol.               IN      A

;; ANSWER SECTION:
ns1.sistema.sol.        86400   IN      CNAME   tierra.sistema.sol.
tierra.sistema.sol.     86400   IN      A       192.168.57.103

;; Query time: 0 msec
;; SERVER: 192.168.57.102#53(192.168.57.102) (UDP)
;; WHEN: Wed Nov 22 18:17:35 CET 2023
;; MSG SIZE  rcvd: 109
```

Resultado `ns2.sistema.sol`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> ns2.sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47421
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 4903b74b29cc8f1001000000655e383d867e15989a966cbd (good)
;; QUESTION SECTION:
;ns2.sistema.sol.               IN      A

;; ANSWER SECTION:
ns2.sistema.sol.        86400   IN      CNAME   venus.sistema.sol.
venus.sistema.sol.      86400   IN      A       192.168.57.102

;; Query time: 0 msec
;; SERVER: 192.168.57.103#53(192.168.57.103) (UDP)
;; WHEN: Wed Nov 22 18:19:57 CET 2023
;; MSG SIZE  rcvd: 108

```

Resultado `dig NS sistema.sol`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> NS sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 2998
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: a250ae69cea468f701000000655e3968f7f9b7b57988e10f (good)
;; QUESTION SECTION:
;sistema.sol.                   IN      NS

;; ANSWER SECTION:
sistema.sol.            86400   IN      NS      venus.sistema.sol.
sistema.sol.            86400   IN      NS      tierra.sistema.sol.

;; ADDITIONAL SECTION:
venus.sistema.sol.      86400   IN      A       192.168.57.102
tierra.sistema.sol.     86400   IN      A       192.168.57.103

;; Query time: 0 msec
;; SERVER: 192.168.57.103#53(192.168.57.103) (UDP)
;; WHEN: Wed Nov 22 18:24:56 CET 2023
;; MSG SIZE  rcvd: 141

```

Resultado `dig MX sistema.sol`
```
; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> MX sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 17742
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: f263f6c45bcc902a01000000655e399ef9fc9e8d904b84e8 (good)
;; QUESTION SECTION:
;sistema.sol.                   IN      MX

;; ANSWER SECTION:
sistema.sol.            86400   IN      MX      10 marte.sistema.sol.

;; ADDITIONAL SECTION:
marte.sistema.sol.      86400   IN      A       192.168.57.104

;; Query time: 4 msec
;; SERVER: 192.168.57.103#53(192.168.57.103) (UDP)
;; WHEN: Wed Nov 22 18:25:50 CET 2023
;; MSG SIZE  rcvd: 106
```

Comprueba que se ha realizado la transferencia de la zona entre el servidor DNS maestro y el esclavo.
Log del comando `systemctl status bind9`
```
nov 22 18:24:24 venus named[1378]: client @0x7f1fd4903968 192.168.57.103#52408: received notify for zone 'sistema.sol'
nov 22 18:24:24 venus named[1378]: zone sistema.sol/IN: notify from 192.168.57.103#52408: zone is up to date
nov 22 18:24:46 venus named[1378]: client @0x7f1fd4903968 192.168.57.103#39079: received notify for zone 'sistema.sol'
nov 22 18:24:46 venus named[1378]: zone sistema.sol/IN: notify from 192.168.57.103#39079: serial 2
nov 22 18:24:46 venus named[1378]: zone sistema.sol/IN: Transfer started.
nov 22 18:24:46 venus named[1378]: transfer of 'sistema.sol/IN' from 192.168.57.103#53: connected using 192.168.57.103#53
nov 22 18:24:46 venus named[1378]: zone sistema.sol/IN: transferred serial 2
nov 22 18:24:46 venus named[1378]: transfer of 'sistema.sol/IN' from 192.168.57.103#53: Transfer status: success
nov 22 18:24:46 venus named[1378]: transfer of 'sistema.sol/IN' from 192.168.57.103#53: Transfer completed: 1 messages, 11 records, 272 bytes, 0.001 secs (272000 bytes/sec) (serial 2)
nov 22 18:24:46 venus named[1378]: zone sistema.sol/IN: sending notifies (serial 2)

```
