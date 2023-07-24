#!/usr/env/bash

set -eEuo pipefail

## Disable memory swap
sudo swapoff -a

## Edit hosts file
# sudo vim /etc/hosts  !!

# Add all the server ips and correspond names in `/etc/hosts` file.
# 172.31.44.88 master
# 172.31.44.219 worker1 !!

## Edit machine names
sudo hostnamectl set-hostname <correspond_namesr> #e.g. maste


## Prepare installing container runtime
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
  overlay
  br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-iptables  = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

## Install Containerd

sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
service containerd status

## Install kubelet, kubeadm, kubectl
## MOST be ALL in SAME $VERSION...
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo mkdir -p /etc/apt/keyrings
sudo chmod -R a=---,u=rw,go=r /etc/apt/keyrings
sudo curl -fsSLo /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

## Kubeadm init
sudo kubeadm init # on master
