#! /bin/bash
chmod 600 /root/.ssh/authorized_keys
chown 0:0 /root/.ssh/authorized_keys
touch /root/.hushlogin
set > /root/.ssh/environment
echo "cd /data" >> /root/.ssh/rc
/usr/sbin/sshd -D -e
