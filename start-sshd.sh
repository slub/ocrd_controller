#! /bin/bash
nohup broadwayd $BROADWAY_DISPLAY &
cat /authorized_keys >> /.ssh/authorized_keys
touch /.hushlogin
set | fgrep -ve BASH > /.ssh/environment
echo "cd /data" >> /.ssh/rc
echo "umask $UMASK" >> /.ssh/rc
chmod go-rwx /.ssh/*
chown $UID:$GID /.ssh/*
echo ocrd:x:$UID:$GID:SSH user:/:/bin/bash >> /etc/passwd
echo ocrd:*:19020:0:99999:7::: >> /etc/shadow
#/usr/sbin/sshd -D -e
service ssh start
service rsyslog start
sleep 1
tail -f /var/log/syslog
