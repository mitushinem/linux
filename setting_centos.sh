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
/etc/rsyslog.d && mcedit ignore-systemd-session-slice.conf
if $programname == "systemd" and ($msg contains "Starting Session" or $msg contains "Started Session" or $msg contains "Created slice" or $msg contains "Starting user-" or $msg contains "Starting User Slice of" or $msg contains "Removed session" or $msg contains "Removed slice User Slice of" or $msg contains "Stopping User Slice of") then stop
systemctl restart rsyslog

echo 'Отключить SELinux'
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

systemctl disabled iptables
systemctl stop firewalld
systemctl disabled firewalld

sudo sed -i '$a alias netstat="netstat -tulpn"' ./.bashrc
source ./.bashrc

reboot
