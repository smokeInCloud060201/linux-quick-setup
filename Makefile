# Makefile for setup tasks

# Target: init
# Description: Update package lists
init:
	sudo apt update

# Target: install-java
# Description: Install OpenJDK 17 and set JAVA_HOME
install-java:
	@echo "Installing OpenJDK 17..."
	sudo apt install openjdk-17-jdk -y
	@echo "Setting JAVA_HOME..."
	@echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> ~/.profile
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
setup: init install-java install-maven setup-env ibus-bamboo

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
