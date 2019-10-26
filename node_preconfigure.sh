# Edit your /etc/hosts
# 192.168.1.11 kpi1
# 192.168.1.12 kpi2
# 192.168.1.13 kpi3
# 192.168.1.14 kpi4
# 192.168.1.15 kpi5
# 192.168.1.16 kpi6
# None of these entries are necessary if your router learns dns names
# And none of them are necessary for kubernetes. They're simply here for ssh access
# 192.168.1.198 radish 

# You'll have to do this step on the PI console unless you want DHCP all over the place
# ****** IMPORTANT **********************
# add this line, uncommented, to assign the static IP address of your node. Make sure the spacing matches. It should look like this
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
sudo netplan --debug try # If this fails, fix it before continuing
sudo netplan --debug generate
sudo netplan --debug apply

# ******************* Next Stage *****************
# DO THIS STEP ON EVERY NODE! DO NOT SKIP
# At this point, go to your workstation and open a terminal
ssh ubuntu@192.168.1.11

sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline_backup.txt
orig="$(head -n1 /boot/firmware/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory hdmi_force_hotplug=1"
echo $orig | sudo tee /boot/firmware/cmdline.txt

# Need to reboot to apply the /boot/firmware/cmdline.txt because docker won't run without it.
# Do this now because if we ever automate this, this is the minimum requirement before triggering with chef
reboot


# ****************** Next Stage ***********************
# From this point on, we should be able to automate these steps with Chef or Ansible.
# I haven't gotten that far.
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


# ************** Next Stage ***************
# I do these commands in small blocks in case something goes wrong.

# Install the required packages for ubuntu 18.04 on Raspberry Pi
sudo apt update; sudo apt upgrade -y
sudo apt install nfs-common -y

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

# Edit your /etc/hosts
192.168.1.11 kpi1
192.168.1.12 kpi2
192.168.1.13 kpi3
192.168.1.14 kpi4
192.168.1.15 kpi5
192.168.1.16 kpi6
# None of these entries are necessary if your router learns dns names
# And none of them are necessary for kubernetes. They're simply here for ssh access
192.168.1.198 radish 

# This is necessary
# Enable forwarding for CIDR
sudo vi /etc/sysctl.conf
:28
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1

# Once this has been done on all the hosts you want to use in the cluser,
# Switch to your regular workstation. Get all the certificates passed all at once
# Run ssh-keygen if you haven't already
# ssh-keygen
ssh-copy-id ubuntu@kpi1
ssh-copy-id ubuntu@kpi2
ssh-copy-id ubuntu@kpi3
ssh-copy-id ubuntu@kpi4
ssh-copy-id ubuntu@kpi5
ssh-copy-id ubuntu@kpi6

# Allow the updates to sort themselves out and ip forwarding to do its thing
ssh -t ubuntu@kpi1 "sudo reboot"
ssh -t ubuntu@kpi2 "sudo reboot"
ssh -t ubuntu@kpi3 "sudo reboot"
ssh -t ubuntu@kpi4 "sudo reboot"
ssh -t ubuntu@kpi5 "sudo reboot"
ssh -t ubuntu@kpi6 "sudo reboot"

# **************** Next Stage **********************
# **************************************************
# ****** MASTER NODE *******************************

# sudo kubeadm reset

# Initialize kubernetes with a pod network CIDR of 10.64.x.x and a service CIDR of 100.65.x.x
# This takes a while to run
# *************** IMPORTANT ******************
# The following command produces a connect command that you will need for your
# nodes to join. DO NOT LOSE IT, BUT DEFINITELY SECURE IT! This string gives access to your master.
sudo kubeadm init --pod-network-cidr=100.64.0.0/16 --service-cidr=100.65.0.0/16 --node-name kpi1

# ********* CAPTURE JOIN COMMAND ********************
# ****** PUT LATEST JOIN COMMAND ON TOP *************
# Not that the kubeadm output from the above command does not include sudo. You will have to add that yourself
sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
# sudo kubeadm join 192.168.1.11:6443 --token 4udwzs.2vh71584junwx8jv --discovery-token-ca-cert-hash sha256:0dedf718aef8f1a1837214d254fdfe1814c09c207d8bda836e65127942b42b05 
# sudo kubeadm join 192.168.1.11:6443 --token qhls31.2mjmabcegf7xyydb --discovery-token-ca-cert-hash sha256:2b3dfaf1c5591858a805f65ea0aff09b3bb3b43ce207ddb0e2e36440e6431aa5 

# ********* IMPORTANT ************
# When finished, copy the keys to your own (ubuntu) directory
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# scp $HOME/.kube/config jeff@radish:/home/jeff/ # not into .kube unless you want to overwrite

# Copy the YAML files from wherever they're stored.
mkdir kube
cd kube
# scp -r jeff@radish:/home/jeff/kube/ /home/ubuntu/kube

# Now, install flannel. https://coreos.com/flannel/docs/latest/
# Flannel will provide the network layer since the cloud can't. Line 128 defines my pod network to match the kubeadm init above
kubectl create -f kube-flannel.yaml 

# Verify it finished
kubectl get pods -o wide --all-namespaces

# Install metallb. https://metallb.universe.tf/
# Metallb provides bare metal load balancing. Can be used as Ingress substitute
kubectl create -f metallb.yaml

# Verify it finished
kubectl get pods -o wide --all-namespaces

# Install the metallb ConfigMap
# You'll need to edit this for your own network
kubectl create -f metal-l2.yam

# Verify it finished
kubectl get pods -o wide --all-namespaces

# That's it! You've done the minimum install of a single node kubernetes cluster
# It's not at all useful, yet.

# Let's join a node
# Do not use my command. That server is long since dead, anyway. Use your string that
# you copied from the kubeadm init you ran on the master node. I did tell you to save it.

# From your workstation
ssh ubuntu@kpi2
# sudo kubeadm reset
sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
# Install the nfs client on all workers (not the master, though)
sudo apt install nfs-common -y
exit

# That's it. The node is joined.

# Do it again
ssh ubuntu@kpi3
# sudo kubeadm reset
sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
sudo apt install nfs-common -y
exit
# And again
ssh ubuntu@kpi4
# sudo kubeadm reset
sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
sudo apt install nfs-common -y
exit
# And again
ssh ubuntu@kpi5
# sudo kubeadm reset
sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
sudo apt install nfs-common -y
exit

# **************** HOWEVER *****************
# Don't join the last node. Let's put some io resources there where they
# won't get abused by kubelets
# On NFS Server (kpi6)
# NOTE: You do not need an nfs server. I'm installing one. You do you.
ssh ubuntu@kpi6
sudo apt install nfs-kernel-server

# Your UUID string will differ. Get it from `sudo blkid` and look for the SSD drive you had laying around
sudo vi /etc/fstab
UUID=95b55dff-3177-49b7-81f0-26531d60ea7e /ssd	ext4  defaults 0 0

# Run this
sudo mount -a

sudo vi /etc/exports
# Edit this to be more secure
/ssd/pv1	*(rw,sync,no_root_squash)
#/ssd/pv2	*(rw,sync,no_root_squash)

# Run this
sudo systemctl restart nfs-kernel-server
# We're done with this host (If something goes wrong, you may need to come back)
exit

# ******************************** Next Stage ******************************
# Go back to the master node
ssh ubuntu@kpi1
cd kube

# Install the PersistentVolume and PersistentVolumeClaim for the nginx web host.
kubectl create -f nginx-nfs-pv.yaml

# Install a couple of instances of nginx to serve our page
kubectl create -f nginx.yaml

# Test that it's started
kubectl get services

# Note the external ip address of this host. This is the external IP. 
# It's on a node somewhere. Try it from a web browser on your network.
http://192.168.1.40/
