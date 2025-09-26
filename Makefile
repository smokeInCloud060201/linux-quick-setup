# Makefile for setup tasks

# Target: init
# Description: Update package lists
init:
	sudo apt update

# Target: install-java
# Description: Install OpenJDK 17 and set JAVA_HOME
install-java:
	@echo "Installing OpenJDK 17..."
	sudo apt install openjdk-21-jdk -y
	@echo "Setting JAVA_HOME..."
	@echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> ~/.profile
	@echo "export PATH=\$$JAVA_HOME/bin:\$$PATH" >> ~/.profile
	@export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Target: install-maven
# Description: Install Maven and set M2_HOME
install-maven:
	@echo "Installing Maven..."
	sudo apt install maven -y
	@echo "Setting M2_HOME..."
	@echo "export M2_HOME=/usr/share/maven" >> ~/.profile
	@echo "export PATH=\$$M2_HOME/bin:\$$PATH" >> ~/.profile
	@export M2_HOME=/usr/share/maven

# Target: setup-env
# Description: Update environment variables
setup-env:
	@echo "Updating environment variables..."
	@if [ -f ~/.profile ]; then \
		. ~/.profile; \
	fi

# Target: setup
# Description: Perform initial setup (update, install Java, install Maven)
setup: init install-java install-maven setup-env ibus-bamboo nvm node-20

# Target: git
# Description: Install Git and check version
git:
	@echo "Starting Git installation..."
	sudo apt install git -y
	git --version


ibus-bamboo:
	sudo add-apt-repository ppa:bamboo-engine/ibus-bamboo
	sudo apt-get update
	sudo apt-get install ibus ibus-bamboo --install-recommends -y
	ibus restart
	env DCONF_PROFILE=ibus dconf write /desktop/ibus/general/preload-engines "['BambooUs', 'Bamboo']" && gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Bamboo')]"
	im-config -n ibus

docker-engine:
	sudo apt install -y apt-transport-https ca-certificates curl gnupg
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/dockerce.gpg
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/dockerce.gpg] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/dockerce.list > /dev/null
	sudo apt update
	sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
	sudo docker version
	sudo groupadd docker
	sudo usermod -aG docker $USER
	newgrp docker
	docker run hello-world

nvm:
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

node-20:
	nvm install v20.15.1
	node --version
	npm --version
	npm install -g yarn
	yarn --version


k8s:
	sudo swapoff -a
	sudo sed -i '/ swap / s/^/#/' /etc/fstab
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
	sudo dpkg -i minikube_latest_amd64.deb
	minikube start
	minikube start --driver=docker
	minikube kubectl -- get po -A
	@echo 'alias kubectl="minikube kubectl --"' >> ~/.bashrc

vm:
	sudo apt update
	sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y
	lsmod | grep kvm
	sudo systemctl enable --now libvirtd
	groups $USER
	newgrp libvirt
	sudo virsh net-start default
	sudo virsh net-autostart default


vm-ip-address:
	virsh net-dhcp-leases default

k8s-vm-base:
	sudo apt update && sudo apt upgrade -y
	sudo apt install -y containerd
	sudo mkdir -p /etc/containerd
	containerd config default | sudo tee /etc/containerd/config.toml
	sudo systemctl restart containerd
	sudo swapoff -a
	sudo sed -i '/ swap / s/^/#/' /etc/fstab
	sudo apt install -y apt-transport-https ca-certificates curl gpg
	sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg
	echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
	sudo apt update
	sudo apt install -y kubelet kubeadm kubectl
	sudo apt-mark hold kubelet kubeadm kubectl
	sudo modprobe br_netfilter
	sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
	sudo sysctl --system
	cat /proc/sys/net/bridge/bridge-nf-call-iptables
	cat /proc/sys/net/ipv4/ip_forward  

k8s-master: 
	sudo kubeadm init --pod-network-cidr=10.244.0.0/16
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config

k8s-master-create-token:
	sudo kubeadm token create --print-join-command

k8s-worker-config-kubeadm:
	sudo kubeadm config images pull

