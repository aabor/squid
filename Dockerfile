FROM ubuntu/squid:4.10-20.04_edge

RUN apt-get update && apt-get install apache2-utils -y

COPY squid.conf /etc/squid/squid.conf