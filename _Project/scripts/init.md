
# Kubernetes Installation Steps

## What we need to install


* On `Control Plane` & `Worker`
    * Container Runtime (Run as regular Linux process)
    * Kubelet (Run as regular Linux process)
    * Kube Proxy (Pod)
* Only on `Control Plane`
    * Api Server (Pod)
    * Scheduler (Pod)
    * Controller Manger (Pod)
    * ETCD (Pod)


## Static Pods

<div id="Kubernetes-Installation-Steps-Static-Pods">

* Master components deployed as Pods
* Pods are deployed by master components
    * Send a request to `API Server`
    * `Scheduler` decides where to place Pod
    * Pod data stored in `etcd` store
* How to schedule the Master Pods then? (The Egg and Chicken Problem!)

---

Static Pods

* Are managed directly by the kubelet daemon
* Without control plane

---

* Regular Pod Scheduling
    * `API Server` gets the request
    * `Scheduler`: which Node?
    * `Kubelet`: schedules Pod
* Static Pod Scheduling
    * `Kubelet`: schedules Pod

---

How does that work?

* Kubelet **watches a specific location** on the Node it is running
    * `/etc/kubernetes/manifests`
* Schedules Pod, when it finds a "Pod" manifest

---

* Why is it called **static** Pod?
* How is it **different**?

* Kubelet (NOT Controller Manager) watches static Pods and restarts them if they fail
* Pod names are **suffixed with the node hostname**

* First step when installing K8s cluster
    * Generate static Pods manifests
    * Put those config files into the correct folder

</div> <!-- Static Pods -->

## Certificates

<div id="Kubernetes-Installation-Steps-Certificates">

Everything needs a certificate...

How does it work?

* Generate self-signed CA certificate for Kubernetes (cluster root CA)
* Sign all client and server certificates with it
* Certificates are stored in: `/etc/kubernetes/pki`
* Each component gets a certificate, **signed by the same certificate authority**
* Proof that components identify and that its part of the same cluster

---

1) Generate a **self-signed CA certificate** for the whole Kubernetes cluster (`cluster root CA`)
2) Sign all client and server certificates with it
    * `Server certificate` for the API server endpoint
    * `Client certificate` for scheduler and controller manager
    * `Server certificate` for Etcd and Kubelet
    * `Client certificate` for API Server to talk to Kubelet and Etcd
    * `Client certificate` for Kubelet to authenticate to API Server

---

Public Key Infrastructure

* Governs the issuance of certificates to:
    * [X] Protect sensitive data
    * [X] Provide unique digital identities for applications, users and devices
    * Secure end-to-end communication

</div> <!-- Certificates -->

## Kubeadm

<div id="Kubernetes-Installation-Steps-Kubeadm">

For a K8s cluster, we need to do all the steps above + some other configuration details we need to provide

But it is complex and time consuming, when doing it manually

---

* Kubeadm
    * Toolkit for bootstrapping a best-practices K8s cluster

* Providing fast paths for creating K8s cluster
* Performs the actions necessary to get a minimum viable cluster
* It cares only about bootstrapping, not about provisioning machines
* [Maintained by Kubernetes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

</div> <!-- Kubeadm -->

# Preparing the servers


<!-- ////////////////////////////////////// -->

<div id="prepare-servers">  
This is how we prepare our bare-metal servers...
</div>


## Disable memory swap

<div id="disable-memory-swap">

* All
  ```shell
  sudo swapoff -a
  ```

</div>

## Edit hosts file

<div id="edit-hosts-file">

* All
  ```shell
  sudo vim /etc/hosts
  ```

* Add all the server ips and correspond names in `/etc/hosts` file, e.g.
  ```text
  172.31.44.88 master
  172.31.44.219 worker1
  172.31.37.5 worker2
  ```

</div>

## Edit machine names

<div id="edit-hosts-names">

* All
  ```shell
  sudo hostnamectl set-hostname <correspond names e.g. master>
  ```

</div>

## Prepare installing container runtime

<div id="prepare-installing-container-runtime">

* All
  ```shell
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
  ```

</div>

## Install Containerd

<div id="install-containerd">

* All
  ```sh
  sudo apt update
  sudo apt install -y containerd
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml
  sudo systemctl restart containerd
  service containerd status
  ```

</div>

## Install kubelet, kubeadm, kubectl

<div id="install-3k">

* Kubelet
    * Does things like **starting pods** and containers
    * Components that runs on all the machines in your cluster
* Kubeadm
    * Command line tool to **initialize the cluster**
* Kubectl
    * Command line tool to **talk to the cluster**

* All
  ```sh
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl
  sudo mkdir -p /etc/apt/keyrings
  sudo chmod -R a=---,u=rw,go=r /etc/apt/keyrings
  sudo curl -fsSLo /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  ```

NOTE-1: Kubelet, Kubeadm and Kubectl MOST be ALL in SAME VERSION...
<br />
NOTE-2: For seeing all available versions, use:

Use the `apt-cache madison kubeadm` to get started.

* All
  ```sh
  sudo apt-get update
  sudo apt-get install -y kubelet=<VERSION> kubeadm=<VERSION> kubectl=<VERSION>
  sudo apt-mark hold kubelet kubeadm kubectl
  ```

</div>

## Kubeadm init

<div id="kubeadm-init">

<h5>kubeadm init phrase</h5>
<ol>
  <li>preflight</li>
    <ul>Checks to validate the system state making any changes</ul>
  <li>certs</li>
    <ul>Generate a self-signed CA to set up identities for each component in the cluster</ul>
  <li>kubeconfig</li>
    <ul>writes kubeconfig files in `/etc/kubernetes`</ul>
</ol>

* Master
  ```sh
  sudo kubeadm init
  ```

</div>
