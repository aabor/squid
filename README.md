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