#!/usr/bin/env bash

echo '### 0.update yum repos'
rm /etc/yum.repos.d/CentOS-Base.repo
rm -f /etc/yum.repos.d/epel*.repo
cp /vagrant/yum/*.* /etc/yum.repos.d/
yum clean all
yum makecache fast

echo '### 1.install common libs'
yum install -y git wget curl vim htop \
  epel-release conntrack-tools net-tools telnet tcpdump bind-utils socat \
  ntp chrony kmod ceph-common dos2unix ipvsadm ipset jq iptables bridge-utils libseccomp

echo '### 2.update locale'
cat <<EOF | sudo tee -a /etc/environment
LANG=en_US.utf8
LC_CTYPE=en_US.utf8
EOF

echo '### 3.disable selinux'
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

echo '### 4.disable firewalld'
systemctl stop firewalld
systemctl disable firewalld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
iptables -P FORWARD ACCEPT

echo '### 5.disable swap'
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

echo '### 6.optimize linux kernel parameters'
cp /vagrant/sysctl/kubernetes.conf  /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf

echo '### 7.change timezone'
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai

echo '### 8.sync time'
systemctl enable chronyd
systemctl start chronyd
timedatectl status
timedatectl set-local-rtc 0
systemctl restart rsyslog
systemctl restart crond

echo '### 9.disable useless system server'
systemctl stop postfix && systemctl disable postfix

echo '### 10.install docker'
yum install -y yum-utils device-mapper-persistent-data lvm2
yum -y install docker-ce-18.09.9

mkdir -p /etc/docker
cat /vagrant/docker/daemon.json > /etc/docker/daemon.json
cat /vagrant/systemd/docker.service > /usr/lib/systemd/system/docker.service

echo '### 11.enable docker service'
systemctl daemon-reload
systemctl enable docker
systemctl start docker

echo '### 12.install and enable kubeadm'
#yum install -y kubelet-1.16.8 kubeadm-1.16.8 kubectl-1.16.8 --disableexcludes=kubernetes
yum install -y kubelet-1.18.4 kubeadm-1.18.4 kubectl-1.18.4 --disableexcludes=kubernetes
systemctl enable --now kubelet

echo "### 13.permit root login"
/bin/cp -rf /vagrant/ssh/sshd_config /etc/ssh/sshd_config
service sshd restart

echo '### 14.info output'
docker --version
docker info
kubelet --version
kubeadm version

echo '### 15.add vagrant public key'
sudo -u vagrant wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
chmod go-w /home/vagrant/.ssh/authorized_keys
cat /home/vagrant/.ssh/authorized_keys


echo '### 16.clean data'
yum clean all # 清除yum操作缓存
rm -rf /tmp/* # 清除tmp下的零时文件
rm -f /var/log/wtmp /var/log/btmp # 清除日志
history -c # 清除历史
shutdown -h now # 立即关机

