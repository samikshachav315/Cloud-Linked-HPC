#!/bin/bash
# PCS, Corosync, Pacemaker Installation
sudo nano /etc/hosts
sudo apt update
sudo apt upgrade -y
sudo apt install -y pacemaker corosync pcs
pcs --version
corosync -v
pacemakerd –version
systemctl list-unit-files | grep -E "corosync|pacemaker|pcsd"
sudo passwd hacluster
sudo systemctl start pcsd
sudo systemctl enable pcsd
sudo systemctl start pcsd

#Corosync Configuration
sudo pcs host auth controller-1 controller-2 -u hacluster -p Prashant@98
sudo pcs cluster setup cloudcluster controller-1 controller-2
sudo pcs cluster setup cloudcluster controller-1 controller-2 -f
sudo cat /etc/corosync/corosync.conf
sudo pcs property set no-quorum-policy=ignore

#Starting the Cluster
sudo pcs cluster start --all
sudo pcs cluster enable --all
sudo pcs cluster status
sudo pcs status

# Create VIP Resource (AWS Overlay IP)
sudo pcs resource 
create cluster_vip ocf:heartbeat:aws-vpc-move-ip 
ip=192.168.2.50 
interface=enp39s0 
region=us-east-1 
awscli=/usr/bin/aws 
op monitor interval=30s --force
