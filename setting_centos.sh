echo 'Обновление системы'
dnf install -y epel-release
dnf check-update
dnf update -y
dnf clean all

setenforce 0

echo 'Ставим нужные пакеты'
dnf install -y mc vim net-tools curl bind-utils network-scripts iptables-services iftop htop lsof wget bzip2 traceroute gdisk bash-completion

echo 'Настройка времени'
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
timedatectl set-timezone Europe/Moscow

echo 'Отключаем флуд сообщений в /var/log/messages'
touch /etc/rsyslog.d/ignore-systemd-session-slice.conf 
echo 'if $programname == "systemd" and ($msg contains "Starting Session" or $msg contains "Started Session" or $msg contains "Created slice" or $msg contains "Starting user-" or $msg contains "Starting User Slice of" or $msg contains "Removed session" or $msg contains "Removed slice User Slice of" or $msg contains "Stopping User Slice of") then stop' >> /etc/rsyslog.d/ignore-systemd-session-slice.conf
systemctl restart rsyslog

echo 'Отключить SELinux'
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

systemctl disabled iptables
systemctl stop firewalld
systemctl disabled firewalld

sudo sed -i '$a alias netstat="netstat -tulpn"' ./.bashrc
source ./.bashrc

echo 'Установка Zabbix proxy 5.0.1'
dnf -y install http://mirror.centos.org/centos/8.0.1905/AppStream/x86_64/os/Packages/libssh2-1.8.0-8.module_el8.0.0+189+f9babebb.1.x86_64.rpm
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
dnf -y install zabbix-proxy-mysql

dnf -y install mariadb-server && systemctl start mariadb && systemctl enable mariadb
mysql_secure_installation
mysql -uroot -p'qwer1234++' -e "create database zabbix_proxy character set utf8 collate utf8_bin;"
mysql -uroot -p'qwer1234++' -e "grant all privileges on zabbix_proxy.* to zabbix@localhost identified by 'zabbixDBpass';"
mysql -uroot -p'qwer1234++' zabbix_proxy -e "set global innodb_strict_mode='OFF';"
zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz |  mysql -uzabbix -p'qwer1234++' zabbix_proxy
mysql -uroot -p'rootDBpass' zabbix_proxy -e "set global innodb_strict_mode='ON';"

reboot
