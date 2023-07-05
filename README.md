# Squid Proxy based on Ubuntu Docker Image from Canonical #

Squid proxy with basic authorisation to cash internet traffic. 

I use Squid Docker Image from Canonical, based on Ubuntu:
https://registry.hub.docker.com/r/ubuntu/squid

## Run Squid proxy on localhost ##

Clone the repository and `cd` to it

```sh
# create catalogs to hold access credentials, logs and squid data
mkdir -p ~/.squid/log ~/.squid/data
touch ~/.squid/.hdpasswd
# create access credentials for `proxyuser`
htpasswd ~/.squid/.hdpasswd proxyuser

docker-compose build 
docker image ls | grep squid
# aabor/squid          4.10-20.04_edge   993dabd241db   About an hour ago   226MB
# ubuntu/squid         4.10-20.04_edge   e00cc5b0919b   About an hour ago   225MB

docker-compose up -d
docker ps
# 5a7f877f1d94   aabor/squid:4.10-20.04_edge   "entrypoint.sh -f /e…"   About an hour ago   Up 3 seconds   0.0.0.0:3128->3128/tcp   squid-proxy
```

Test connection with Squid proxy

```sh
# To test your proxy, send a request via it. In case of success, the reply must be something like below
curl -x http://localhost:3128 --proxy-user proxyuser:<pwd> -I https://google.com
# HTTP/1.1 200 Connection established
# HTTP/2 301 
# location: https://www.google.com/
# content-type: text/html; charset=UTF-8
# content-security-policy-report-only: object-src 'none';base-uri 'self';script-src 'nonce-Z9dd64hJ4DtGt25W2DZElA' 'strict-dynamic' 'report-sample' 'unsafe-eval' 'unsafe-inline' https: http:;report-uri https://csp.withgoogle.com/csp/gws/other-hp
# date: Mon, 03 Jul 202* 16:45:28 GMT
# expires: Wed, 02 Aug 202* 16:45:28 GMT
# cache-control: public, max-age=2592000
# server: gws
# content-length: 220
# x-xss-protection: 0
# x-frame-options: SAMEORIGIN
# alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000

# try authenticate with wrong password
curl -x http://localhost:3128 --proxy-user proxyuser:wrongpw -I https://google.com
# HTTP/1.1 407 Proxy Authentication Required
# Server: squid/4.10
# Mime-Version: 1.0


# check squid proxy logs
tail ~/.squid/log/access.log
# 1688402728.488   1084 172.19.0.1 TCP_TUNNEL/200 7945 CONNECT google.com:443 - HIER_DIRECT/*.*.*.* -
tail ~/.squid/log/cache.log
```

## Add squid proxy to Firefox

By default firefox does not allow proxy servers with basic authentication.

Install plugin https://addons.mozilla.org/en/firefox/addon/foxyproxy-standard/

Select FoxyProxy icon on browser panel and go to options.
Add proxy IP address (localhost if its running on the localhost), port and user credentials.
Test browsing Internet. If username or password are wrong then Firefox will popup dialog box to enter basic authentication credentials.
See also access logs to make sure that all the traffic goes through proxy server.
```sh
tail ~/.squid/log/access.log
# 170242 172.19.0.1 TCP_TUNNEL/200 4739 CONNECT incoming.telemetry.mozilla.org:443 proxyuser HIER_DIRECT/34.120.208.123 -
# 170880 172.19.0.1 TCP_TUNNEL/200 6087 CONNECT googleads.g.doubleclick.net:443 proxyuser HIER_DIRECT/142.251.33.66 -
#      1 172.19.0.1 TCP_DENIED/407 4129 CONNECT doh.xfinity.com:443 - HIER_NONE/- text/html
#      0 172.19.0.1 TCP_DENIED/407 4129 CONNECT doh.xfinity.com:443 - HIER_NONE/- text/html
#      0 172.19.0.1 TCP_DENIED/407 4129 CONNECT doh.xfinity.com:443 - HIER_NONE/- text/html
```


# Alpine Linux Squid Proxy on AWS EC2

Configuration details:
https://wiki.alpinelinux.org/wiki/Setting_up_Explicit_Squid_Proxy

```sh
ssh alpine@18.191.145.152
doas su

apk update
apk add bash nano vim curl zip unzip git lsblk
apk add mandoc man-pages mandoc-apropos less
apk add less-doc iptables-doc
apk add tzdata
apk add squid apache2-utils

# echo "America/Los_Angeles" >  /etc/timezone

rc-service squid start
rc-update add squid
squid -k check
mkdir -p /var/spool/squid
nano /etc/squid/.htpasswd
nano /etc/squid/squid.conf

squid -k reconfigure
rc-service squid status
#  * status: started
netstat -tl
Active Internet connections (only servers)
# Proto Recv-Q Send-Q Local Address           Foreign Address         State       
# tcp        0      0 0.0.0.0:ssh             0.0.0.0:*               LISTEN      
# tcp        0      0 :::3128                 :::*                    LISTEN      
# tcp        0      0 :::ssh                  :::*                    LISTEN

```
From the remote
```sh
terraform validate
terraform plan
terraform apply
# try ssh connection
ssh alpine@$(terraform output --raw public_ip)
exit
# try proxy, enter valid password
curl -x $(terraform output --raw public_ip):3128 --proxy-user proxyuser:<pwd> -I https://google.com
# HTTP/1.1 200 Connection established

# HTTP/2 301 
# location: https://www.google.com/
# content-type: text/html; charset=UTF-8
# content-security-policy-report-only: object-src 'none';base-uri 'self';script-src 'nonce-YXmGOZLT-rKpL-Yy1hEKHA' 'strict-dynamic' 'report-sample' 'unsafe-eval' 'unsafe-inline' https: http:;report-uri https://csp.withgoogle.com/csp/gws/other-hp
# date: Tue, 04 Jul 2023 18:50:40 GMT
# expires: Thu, 03 Aug 2023 18:50:40 GMT
# cache-control: public, max-age=2592000
# server: gws
# content-length: 220
# x-xss-protection: 0
# x-frame-options: SAMEORIGIN
# alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000

# try proxy with wrong password
curl -x $(terraform output --raw public_ip):3128 --proxy-user proxyuser:wrong -I https://google.com
# HTTP/1.1 407 Proxy Authentication Required
# Server: squid/5.9
# Mime-Version: 1.0
# Date: Tue, 04 Jul 2023 18:52:24 GMT
# Content-Type: text/html;charset=utf-8
# Content-Length: 3612
# X-Squid-Error: ERR_CACHE_ACCESS_DENIED 0
# Vary: Accept-Language
# Content-Language: en
# Proxy-Authenticate: Basic realm="Squid Basic Authentication"
# X-Cache: MISS from ip-172-31-2-15
# X-Cache-Lookup: NONE from ip-172-31-2-15:3128
# Via: 1.1 ip-172-31-2-15 (squid/5.9)
# Connection: keep-alive

# curl: (56) CONNECT tunnel failed, response 407
```


# Squid on Mac OS

```sh
# /opt/homebrew/etc/squid.conf
# /opt/homebrew/etc/squid.conf.default
# /opt/homebrew/etc/squid.conf.documented
# /opt/homebrew/Cellar/squid/5.9

# to start squid at launch
brew services start squid
# To restart squid after an upgrade:
brew services restart squid
# Or, if you don't want/need a background service you can just run:
/opt/homebrew/opt/squid/sbin/squid -N -d 1

curl -x localhost:3128 -I https://google.com
# HTTP/1.1 200 Connection established
# HTTP/2 301 
# location: https://www.google.com/

ip a show en0
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	inet 192.168.0.17/24 brd 192.168.0.255 en0

sudo nano /opt/homebrew/etc/squid.conf
# uncomment:
# http_access allow localnet
curl -x 192.168.0.17:3128 -I https://google.com

# list all the services
sudo launchctl list
```