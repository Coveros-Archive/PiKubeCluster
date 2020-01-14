# Install Kubernetes on a pile of Raspberry Pi

## My starting hardware

### WARNING: YOU MUST NOT USE A USB HUB TO POWER A RASPBERRY PI ESPECIALLY NOT A STACK OF THEM.
I DON'T CARE HOW MANY PORTS IT HAS. DO NOT DO IT.

## Raspberry Pi 3B+
I started with Six Raspberry Pi in a stack with a pair of fans against the stack
for cooling. 

## Cooling
A pair of stacked 80mm USB-powered fans is the same height as a stack of
 seven Raspberry Pi. Coincidence?
 
 Also, heat sinks. I bought a bag of Raspberry Pi heat sinks on thermal sticker pads.
 It came with three sizes. I've found a use for two of the sizes. I haven't done
 a thermal imaging study of the components to see if the heat sinks do
 any good.
 
## Power
For power to the cluster, I used a 30W multi-port USB charger.  It has 10 ports.

I picked up a bag of 8" micro usb cables for the Raspberry Pi power. The fans
had their own built-in USB cable.

Sadly, the network switch isn't USB powered. I had it laying around. It 
uses a wall-wart. Which is to say that the USB power block also has
a wall-wart. You'll probably need a power strip before you're done.

## Networking
You won't be joining the wireless network. Please, please, don't join the wireless network.

Instead, you'll be adding the hosts to a network switch. I found a cheap switch
that has 20-odd ports. I also picked up a bag of 12" network cables.

#### You will also need a cross-over cable.
You'll need a crossover cable to go between the pi cluster switch
and whatever network you're about to join. Consider the flood of data
that would be about to hit your wireless network if you were about to
run a Kubernetes network over it. Just buy or make the crossover cable and
plug one end into your internet provider's switch and the other end into one
of the open ports on your switch.

## Storage
Each host has a 32GB microSD card. I have a couple of 64GB microSD cards,
but the performance wasn't the same.

These were imaged one at a time on my laptop.
It was a chore, especially since the first few dozen times I tried, I messed up
so badly that it was faster to just re-image all 6 microSD cards.

### Secondary storage
I will be serving up an NFS share from a node. As such, I attached an external
SSD drive (256GB) using a SATA adapter cable. You could use a thumbdrive
just as easily.

Whichever you choose, wait until after you've done the software updates
before you plug in the new file system. For whatever reason, if I had
the drive plugged in during installation, something would go wrong.

## Image
I used the [Raspberry Pi Ubuntu 18.04 64-bit](https://ubuntu.com/download/iot/raspberry-pi) 
installation image and just used the disk image restoration tool on Ubuntu 18
on my laptop. You can use dd if you want. That said, as of this writing,
Ubuntu 19 has been released, and enough things have changed that the following
procedure likely will not work with Ubuntu 19. You'll need to locate the
Version 18 of the Ubuntu image.

I set up an assembly line of microSD cards on a paper plate and a pair of USB adapter
fobs that I picked up wherever one picks up such things. I found that I could only 
image one card at a time, so I'd stick one card in, transfer the image, eject the
microSD card, stick the next one in, start the next image, pull the freshly imaged
card out, put it in a dish, transfer the next microSD
card to the next USB adapter and wait for the image to finish.

Lather, rinse, repeat.

You'll get faster the 10th and 11th time you do it. Hopefully, you won't have to
since you have this handy guide.

At present time, assuming that all the microSD cards are already imaged 
and ready to install and the hardware is wired up, I can install all 6
hosts to include setting the IP addresses.

For reference, it takes approximately 1:04 for Ubuntu 18 to boot on a
Raspberry Pi 3. It takes another 15 seconds or so to enter ubuntu three
times and the new password twice. And, it takes about 45 seconds to
edit the netplan and run the commands to activate it.

Once the Raspberry Pi 3 has started to boot and show messages on the 
console, it is safe to unplug the HDMI port and plug it into the next
Pi and power it on. By doing this to all hosts, you can pipeline the
initial installation. Once they're all started, go back to the first
host and perform the first login. All of the installation will have
already completed, and you can just move the HDMI and keyboard cables
from one host to the next.

## Keyboard and mouse
I have a wireless keyboard with a tiny little usb plug and I wish it were bigger.
You won't need a mouse. It wouldn't help, anyway. Most of your access to
the cluster will be over ssh, but you will need a keyboard during the initial
install of each host.

## Monitor
You will need an HDMI monitor. You'd like to think that you'll be able to
plug in the monitor after the Pi has booted. You'd be wrong. If it isn't 
plugged in when you boot the Pi, you'll have to start over.

Once you've done the initial networking install, you won't need the monitor
anymore. I leave mine plugged into the master node along with the USB 
fob for the keyboard because the master is the one most likely to act up.

For now, plug the monitor into the top Pi in your cluster.

## Installation
I like to start with all of the Raspberry Pis unplugged from the power
block. Unless you have 6 keyboards and 6 monitors, you'll be doing this 
part one host at a time.

##### Multi-tasking.
If you're quick on your feet, you can be installing host 1 while the
image for host 2 is being copied. Don't lose track of the sd cards that
have been written and the ones that haven't. Before the image has finished
burning, you should be able to accomplish the couple of quick setup
steps and be able to move the monitor cable and keyboard to the next host
so that it's ready when the image finishes.

# Start
Plug in the monitor and the keyboard and make sure that the network
cable is plugged in at each end. Install the microSD card into the slot.

Plug in the power to the host. Wait for the command prompt (about a minute). 

## Log in
Log in to the workstation with the username **ubuntu** and the password
**ubuntu**. You'll be required to change the password, so type **ubuntu**
a *third* time. Then, enter your new password and confirm it.


## Make your nodes static
This step is up to you. I didn't want to worry about how to ssh to dynamic hosts.

Edit /etc/netplan/50-cloud-init.yaml to look like this. You'll need to add the
last line. It must be aligned properly because yaml.

    network:
        version: 2
        ethernets:
            eth0:
                dhcp4: false
                match:
                    macaddress: b8:27:eb:1d:70:0f
                set-name: eth0
                addresses: [192.168.1.11/24] # This is the line you're adding per host
                gateway4: 192.168.1.1
                nameservers:
                    addresses: [8.8.8.8]


Once file has been edited, run this

    sudo netplan --debug try # If this fails, fix it before continuing
    sudo netplan --debug generate
    sudo netplan --debug apply

# Next Stage
### DO THIS STEP ON EVERY NODE! DO NOT SKIP

At this point, go to your workstation and open a terminal
On Ubuntu 18.04

    sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline_backup.txt
    orig="$(head -n1 /boot/firmware/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 hdmi_force_hotplug=1"
    echo $orig | sudo tee /boot/firmware/cmdline.txt

On Raspbian Buster

    sudo cp /boot/cmdline.txt /boot/cmdline_backup.txt
    orig="$(head -n1 /boot/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 hdmi_force_hotplug=1"
    echo $orig | sudo tee /boot/cmdline.txt
    
### You need to reboot to apply the /boot/firmware/cmdline.txt because docker won't run without it.
### Do this now because if we ever automate this, this is the minimum requirement before triggering with chef
### Don't do it during demo, though.

    reboot

## Keep Installing Hosts
Now, move your HDMI cable to the next host. Move the keyboard, give it
power and do the initial password and network setup for each node until
you run out of hosts or patience.

# Next Stage
From this point on, we should be able to automate these steps with Chef or Ansible.
I haven't gotten that far.

#### Do this for each node. They are duplicated here for my convenience

I open 6 terminal windows on one monitor and ssh to each host. Some commands
take a little time and you can paste them in multiple windows at a time.

## Edit your /etc/hosts

None of these entries are 100% necessary if your router learns dns names
And none of them are necessary for kubernetes. They're simply here for ssh access
and if your network doesn't adapt. Also, keep in mind that these IP addresses
will probably conflict with addresses on your home network. 

You should locate any available
addresses before you go all willy-nilly with this. I learned this the hard
way. A number of times, actually.

This code is provided for my convenience,
not yours. I intended on making one node a router and putting all the other
hosts behind that node and serving my own dhcp and you can do that on
your own time. Or, consider contributing to the repo. I'm going to assume 
that you can edit your own hosts file and add the appropriate addresses.
    
    # Add to /etc/hosts
192.168.2.10 kpi0
192.168.2.11 kpi1
192.168.2.12 kpi2
192.168.2.13 kpi3
192.168.2.14 kpi4
192.168.2.15 kpi5
192.168.2.16 kpi6
192.168.2.17 kpi7
192.168.1.198 radish 

Copy these entries and paste them on the appropriate host. Edit as
you see fit for your needs. It is also possible that this step isn't necessary.
If you never again expect to ssh to your nodes, this probably doesn't matter.

    # run on kpi1 (and so on)
    sudo hostnamectl --transient set-hostname kpi0
    sudo hostnamectl --static set-hostname kpi0
    sudo hostnamectl --pretty set-hostname kpi0
 
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

    sudo hostnamectl --transient set-hostname master
    sudo hostnamectl --static set-hostname master
    sudo hostnamectl --pretty set-hostname master

## Enable forwarding for CIDR
You need to uncomment one line and add two new lines on each host. Kubernetes needs
to be able to build a bridge through iptables in order to stitch everything
together with Flannel (later).

    sudo vi /etc/sysctl.conf
    (line 28)
    
    net.ipv4.ip_forward=1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    #net.ipv4.conf.all.arp_ignore=1
    #net.ipv4.conf.all.arp_announce=2


## SSH Convenience

Once this has been done on all the hosts you want to use in the cluser,
Switch to your regular workstation. Get all the certificates passed all at once
Run ssh-keygen if you haven't already and then copy them to each of the nodes.
 
    ssh-keygen
 
 Ubuntu nodes
 
    ssh-copy-id ubuntu@kpi1
    ssh-copy-id ubuntu@kpi2
    ssh-copy-id ubuntu@kpi3
    ssh-copy-id ubuntu@kpi4
    ssh-copy-id ubuntu@kpi5
    ssh-copy-id ubuntu@kpi6
    ssh-copy-id pi@kpi0
    ssh-copy-id pi@kpi7
  
    
Raspbian nodes

    ssh-copy-id pi@kpi1
    ssh-copy-id pi@kpi2
    ssh-copy-id pi@kpi3
    ssh-copy-id pi@kpi4
    ssh-copy-id pi@kpi5
    ssh-copy-id ubuntu@kpi6

# Next Stage 
#### I do these commands in small blocks in case something goes wrong.

## Install the required packages for ubuntu 18.04 on Raspberry Pi
    sudo apt update; sudo apt upgrade -y
    sudo apt install nfs-common -y
    sudo apt install gccgo -y

### Disable Swap
##### This is not necessary on Raspberry Pi Ubuntu Server. It's already off.  It is necessary for raspbian Buster

But, on Raspbian, this will keep coming back unless you put this in rc.local
    sudo vi /etc/rc.local
    
    dphys-swapfile swapoff
    dphys-swapfile uninstall
    update-rc.d dphys-swapfile remove

## Install Docker
On Ubuntu

    sudo apt install docker.io -y
    sudo systemctl enable docker.service
    logout
 
 On Raspbian
 
    curl -sSL get.docker.com | sh && \
    sudo usermod pi -aG docker
    
    logout

Takes about 2 minutes.

## Install Kubernetes
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
    sudo apt-get update -q && \
    sudo apt-get install -qy kubeadm

### Timing
Takes another minute thirty.


##  Allow the updates to sort themselves out and ip forwarding to do its thing
We'll reboot now and also test that the ssh keys were transfered properly.

From your workstation, run these commands.

    ssh -t pi@kpi0 "sudo reboot"
    ssh -t ubuntu@kpi1 "sudo reboot"
    ssh -t ubuntu@kpi2 "sudo reboot"
    ssh -t ubuntu@kpi3 "sudo reboot"
    ssh -t ubuntu@kpi4 "sudo reboot"
    ssh -t ubuntu@kpi5 "sudo reboot"
    ssh -t ubuntu@kpi6 "sudo reboot"
    ssh -t pi@kpi7 "sudo reboot"

## Next Stage

# Master Node Only

    # Don't run this unless you're starting over
    
    sudo kubeadm reset

## Initialize kubernetes with a pod network CIDR of 10.64.x.x and a service CIDR of 100.65.x.x
 This takes a while to run. Be patient.
 
# *************** IMPORTANT ******************
The following command produces a connect command that you will need later for your
nodes to join. DO NOT LOSE IT, BUT DEFINITELY SECURE IT! This string gives access to your master.
   
    sudo kubeadm init --pod-network-cidr=100.64.0.0/16 --service-cidr=100.65.0.0/16 --node-name kpi1

    sudo kubeadm init --pod-network-cidr=100.64.0.0/16 --service-cidr=100.65.0.0/16 --node-name master

### Timing
This takes 4:20 on a Raspberry Pi 3B+

# CAPTURE THE JOIN COMMAND
*Note that the kubeadm output from the above command does not include sudo. You will have to add that yourself.*

The output from one of my runs results in this join string.

    sudo kubeadm join 192.168.2.17:6443 --token hxgcvv.6hr1nofaoxxqt2z6 \
    --discovery-token-ca-cert-hash sha256:3670d0dcedb649cfcf170c15ff92bc26e341ddc7b8e93f6eb05a904e7ecd9607
    
    
    #sudo kubeadm join 192.168.1.11:6443 --token f42uo6.cvq87my0gbeex4r2 \
    #--discovery-token-ca-cert-hash sha256:3280f34bbec798fdb1fc7655ef9299f2796fdb2a1a01225f41d1f1741952e3a2 

    #sudo kubeadm join 192.168.1.11:6443 --token aovs4s.9ffao873c8g8q5en \
    #--discovery-token-ca-cert-hash sha256:a66746189912fe85c57c06e2461a6b248aef128ce6493a5626d8aadc7e9fec65 

    #sudo kubeadm join 192.168.1.11:6443 --token m3tgwq.gt9oordqce4rsa7x \
    #--discovery-token-ca-cert-hash sha256:6f9fbe3b7636af6528a5ebdfc4b7af92706f8184276c0e9b4f2f497be14402af
    
    #sudo kubeadm join 192.168.1.38:6443 --token 8fncgf.0nhxhi51qhjxuuga \
     #   --discovery-token-ca-cert-hash sha256:cf570e7affd34babf2c63fbd8b49b02c01201763a2ac844f760d5dff76b350b6
        
    #sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
    
You'll also need to copy the keys to your own (ubuntu) directory.

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

For my own convenience, I copy the key to a workstation. (4 because it ends up below 1 in my terminal windows)

    scp $HOME/.kube/config ubuntu@kpi4:/home/ubuntu/ # not into .kube unless you want to overwrite

## Copy the YAML files from wherever they're stored.

    mkdir kube
    cd kube
    scp -r jeff@radish:/home/jeff/kube/ ~/kube # Customize this

## Install flannel.

[Flannel](https://coreos.com/flannel/docs/latest/) will provide the network 
layer since the cloud can't. Line 128 defines my pod 
network to match the kubeadm init above.

    kubectl create -f kube-flannel.yaml 

This was quite frustrating since the majority of tutorials and youtube
walk-throughs assume that there is already a network layer provided by
the cloud provider. In our case, we are our own cloud provider. As such
we have to provider our own network.

#### Give it a second and verify it finished

    kubectl get pods -o wide --all-namespaces

## Install Metallb. 
[Metallb](https://metallb.universe.tf/) provides bare metal load balancing.
We'll be using it at the L2 layer, but not with this yaml. This one just
gets it ready to take our ConfigMap.

    kubectl create -f metallb.yaml -f metal-l2.yaml

This was another source of frustration from the online tutorials that
have a cloud provider. The cloud provider already handles the load balancing
service. We don't have that advantage, so we provide it ourselves.

Note that this is not a HaProxy, although it certainly behaves like one.

#### Verify it finished

    kubectl get pods -o wide --all-namespaces

## Install the Metallb ConfigMap
You'll need to edit this for your own network. As it is, this ConfigMap
will generate external addresses in the range 192.168.1.40-45. It's that
way because it was available on my own home network at the time of this
writing.

Don't actually run this. Because of the way that Kubernetes handles restarts,
if this ConfigMap isn't in place immediately (because of a typo or other
hiccup), Kubernetes will go into Restart mode which will simply crush the
Raspberry Pi 3B+. As such, I've included the config map in the metallb.yaml
file. One wouldn't normally include the ConfigMap with the deployment
because the ConfigMap should be fairly unique to the installation.

    # kubectl create -f metal-l2.yam

#### Verify it finished

    kubectl get pods -o wide --all-namespaces

# That's it! You've done the minimum install of a single node kubernetes cluster
It's not at all useful, yet. But, it is officially a running Kubernetes master
running on a Raspberry Pi.

### Do not attempt to install any type of Kubernetes Dashboard!

## Let's join a node
Do not use my command. That server is long since dead, anyway. Use your string that
you copied from the kubeadm init you ran on the master node. I did tell you to save it.

The join token will only last 24 hours. If you want to later join a node,

     kubeadm token create --print-join-command

## From your workstation

    ssh ubuntu@kpi2
    # sudo kubeadm reset
    sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
    # Install the nfs client on all workers (not the master, though)
    sudo apt install nfs-common -y
    exit

#### That's it. The node is joined.

## Do it again

    ssh ubuntu@kpi3
    # sudo kubeadm reset
    sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
    exit

## And again

    ssh ubuntu@kpi4
    # sudo kubeadm reset
    sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
    exit

## And again

    ssh ubuntu@kpi5
    # sudo kubeadm reset
    sudo kubeadm join 192.168.1.11:6443 --token lo25ld.csjutgcpsnxacxqg --discovery-token-ca-cert-hash sha256:a0e01a1cbc7b901a00ff66d5e9dfc5c042499faeeb4eb454095f1fb4766ddfe4
    exit

# HOWEVER 
Don't join the last node. Let's put some io resources there where they
won't get abused by kubelets.

## On NFS Server (kpi6)
*NOTE: You do not need an nfs server. I'm installing one. You do you.*

    ssh ubuntu@kpi6
    sudo apt install nfs-kernel-server
    
    sudo mkdir /ssd # Use what name you want, but be ready to change it where it's used
    
Your UUID string will differ.

    sudo vi /etc/fstab
    UUID=95b55dff-3177-49b7-81f0-26531d60ea7e /ssd	ext4  defaults 0 0

    # Run this
    sudo mount -a
    sudo mkdir /ssd/pv1
    sudo mkdir /ssd/pv2
    
    # Don't run these commands if you already have a website in these directories
    echo "<html><body><b>This is bold text</b></body></html>" > /ssd/pv1/index.html
    echo "<html><body><i>This is italic text</i></body></html>" > /ssd/pv2/index.html
    
    
    sudo vi /etc/exports
    # Edit this to be more secure. This is currently exposed to the world.
    /ssd/pv1	*(rw,sync,no_root_squash)
    /ssd/pv2	*(rw,sync,no_root_squash)
    
    # Run this
    sudo systemctl restart nfs-kernel-server
    # We're done with this host (If something goes wrong, you may need to come back)
    exit

# Next Stage 

Go back to the master node

    ssh ubuntu@kpi1
    cd kube

## Install the PersistentVolume and PersistentVolumeClaim for the nginx web host.
    kubectl create -f nginx-nfs-pv.yaml

## Install a couple of instances of nginx to serve our page
This is actually two instances of nginx pointed at pv1 and one pointed at pv2

    kubectl create -f nginx.yaml

## Test that it's started
    kubectl get services

## Note the external ip address of this host. This is the external IP. 
It's on a node somewhere. Try it from a web browser on your network.
If you didn't change the metal-l2.yaml file, this is probably

[http://192.168.1.40/](http://192.168.1.40/)

# The results
## Performance
Performance is abysmal on the master node. The mandatory pods on the
master find themselves in perpetual error conditions. This matters most
when running kubectl commands that change things.

Adding a pod or a few pods will crush the master node for 15-20 minutes
before settling back down into a stable state.

That said, the other nodes appear to perform just fine. The load balancer
keeps up with a heavy load of static content.

# Add a Raspberry Pi 4B
## Issues:
### Power
3 amp minimum power supply. I tried a 2.4 and a 2.0 amp charger block.
The keyboard wouldn't even come on. I went as far as buying a second
Pi 4 when I was buying the 'official' 15W power supply block. It
wasn't necessary. The power supply fixed the problem.

### HDMI
The Pi 4 uses a microHDMI port. You'll only need the display while
you give yourself a static IP address and do the minimum work necessary
to give yourself SSH access from another workstation.

However, you'll still need that adapter because you'll need to see what
you're doing in order to log in and change the password and set the
address.

Also, the ethernet port and the USB ports are swapped in position between
the Raspberry Pi 3 and the Raspberry Pi 4.
