echo 'Обновление системы'
dnf install -y epel-release
dnf check-update
dnf update -y
#dnf clean all

echo 'Отключить SELinux'
setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
#sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

echo 'Ставим нужные пакеты'
dnf install -y mc vim net-tools curl bind-utils network-scripts cockpit iptables-services iftop htop lsof wget bzip2 traceroute gdisk bash-completion

echo 'Настройка времени'
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
timedatectl set-timezone Europe/Moscow

echo 'Отключаем флуд сообщений в /var/log/messages'
touch /etc/rsyslog.d/ignore-systemd-session-slice.conf 
echo 'if $programname == "systemd" and ($msg contains "Starting Session" or $msg contains "Started Session" or $msg contains "Created slice" or $msg contains "Starting user-" or $msg contains "Starting User Slice of" or $msg contains "Removed session" or $msg contains "Removed slice User Slice of" or $msg contains "Stopping User Slice of") then stop' >> /etc/rsyslog.d/ignore-systemd-session-slice.conf
systemctl restart rsyslog

echo 'Настройка веб управления'
systemctl start cockpit.socket
systemctl enable cockpit.socket

sudo sed -i '$a alias netstat="netstat -tulpn"' ./.bashrc
source ./.bashrc

echo 'Установка Zabbix proxy 5.0.1'

rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
dnf -y install zabbix-proxy-mysql

dnf -y install mariadb-server && systemctl start mariadb && systemctl enable mariadb
mysql_secure_installation
mysql -uroot -p'rootDBpass' -e "create database zabbix_proxy character set utf8 collate utf8_bin;"
mysql -uroot -p'rootDBpass' -e "grant all privileges on zabbix_proxy.* to zabbix@localhost identified by 'zabbixDBpass';"
mysql -uroot -p'rootDBpass' zabbix_proxy -e "set global innodb_strict_mode='OFF';"
zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz |  mysql -uzabbix -p'zabbixDBpass' zabbix_proxy
mysql -uroot -p'rootDBpass' zabbix_proxy -e "set global innodb_strict_mode='ON';"

sed -i 's/Server=127.0.0.1/Server=88.135.48.186/' /etc/zabbix/zabbix_proxy.conf
sed -i 's/Hostname=Zabbix proxy/Hostname=Proxy_0X/' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# DBPassword=/DBPassword=zabbixDBpass/' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartVMwareCollectors=0/StartVMwareCollectors=5/' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# VMwareFrequency=60/VMwareFrequency=60/' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# VMwareCacheSize=8M/VMwareCacheSize=64M/' /etc/zabbix/zabbix_proxy.conf

systemctl restart zabbix-proxy
systemctl enable zabbix-proxy

echo 'Настройка правил фаервола'
systemctl enable firewalld

firewall-cmd -–add-service=ssh --permanent
firewall-cmd --add-service={http,https} --permanent
firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
firewall-cmd --zone=public --add-service=mysql --permanent

firewall-cmd --reload
#reboot
