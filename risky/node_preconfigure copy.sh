#!/bin/sh

sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline_backup.txt
orig="$(head -n1 /boot/firmware/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory hdmi_force_hotplug=1"
echo $orig | sudo tee /boot/firmware/cmdline.txt

# ****** add this line, uncommented, to assign the static IP address of your node. Make sure the spacing matches. It should look like this
#network:
#    version: 2
#    ethernets:
#        eth0:
#            dhcp4: true
#            match:
#                macaddress: b8:27:eb:1d:70:0f
#            set-name: eth0
#            addresses: [192.168.1.11/24]

vi /etc/netplan/50-cloud-init.yaml
addresses: [192.168.1.11/24]
addresses: [192.168.1.12/24]
addresses: [192.168.1.13/24]
addresses: [192.168.1.14/24]
addresses: [192.168.1.15/24]
addresses: [192.168.1.16/24]

# Once file has been edited, run this
sudo netplan --debug try
sudo netplan --debug generate
sudo netplan --debug apply

# apt install chef -y
# https://radish:443

# Need to reboot to apply the /boot/firmware/cmdline.txt because docker won't run without it.
# Do this now because if we ever automate this, this is the minimum requirement before triggering with chef
reboot


#scp kpi1:/home/ubuntu/chef-starter.zip /home/ubuntu
#unzip /home/ubuntu/chef-starter.zip
#cd chef-repo
#knife ssl fetch

# ****************** Next Stage ***********************
# Do this for each node. They are duplicated here for my convenience

sudo hostnamectl --transient set-hostname kpi1
sudo hostnamectl --static set-hostname kpi1
sudo hostnamectl --pretty set-hostname kpi1

sudo hostnamectl --transient set-hostname kpi2
sudo hostnamectl --static set-hostname kpi2
sudo hostnamectl --pretty set-hostname kpi2

sudo hostnamectl --transient set-hostname kpi3
sudo hostnamectl --static set-hostname kpi3
sudo hostnamectl --pretty set-hostname kpi3

sudo hostnamectl --transient set-hostname kpi4
sudo hostnamectl --static set-hostname kpi4
sudo hostnamectl --pretty set-hostname kpi4

sudo hostnamectl --transient set-hostname kpi5
sudo hostnamectl --static set-hostname kpi5
sudo hostnamectl --pretty set-hostname kpi5

sudo hostnamectl --transient set-hostname kpi6
sudo hostnamectl --static set-hostname kpi6
sudo hostnamectl --pretty set-hostname kpi6


# *******************************
# install the required packages for ubuntu 18.04 on Raspberry Pi
sudo apt update; sudo apt upgrade -y

# Install Docker
curl -sSL get.docker.com | sh && \
sudo usermod ubuntu -aG docker

# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
sudo apt-get update -q && \
sudo apt-get install -qy kubeadm

# Disable Swap
# This is not necessary on Raspberry Pi. It would be awful.
#sudo dphys-swapfile swapoff && \
#sudo dphys-swapfile uninstall && \
#sudo update-rc.d dphys-swapfile remove

# /etc/hosts
192.168.1.11 kpi1
192.168.1.12 kpi2
192.168.1.13 kpi3
192.168.1.14 kpi4
192.168.1.15 kpi5
192.168.1.16 kpi6
