doas -s
# switch to user 'aabor'
adduser alpine wheel
adduser -D -g "Alexander Borochkin" aabor
adduser aabor wheel
echo 'permit persist :wheel' >> /etc/doas.d/doas.conf

su -l aabor

NEWUSER='aabor'
mkdir -p /home/$NEWUSER/.ssh
chmod 700 /home/$NEWUSER/.ssh
cp /tmp/id_rsa.pub /home/aabor/.ssh/authorized_keys
chmod 600 /home/$NEWUSER/.ssh/authorized_keys
chown -R $NEWUSER /home/$NEWUSER/.ssh

nano /etc/shadow
# change ! to *
# aabor:*:19518:0:99999:7:::

cp /tmp/.htpasswd /etc/squid/.htpasswd
cp /tmp/squid.conf /etc/squid/squid.conf

echo "America/Los_Angeles" >  /etc/timezone




