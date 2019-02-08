.DEFAULT_GOAL := help

DOTFILES_DIR := $(shell echo $(HOME)/dotfiles)
UNAME := $(shell uname -s)

ifeq ($(UNAME), Darwin)
  OS := macos
else ifeq ($(UNAME), Linux)
  OS := linux
endif

## Bootstrap new host
.PHONY: init
init: install-deps link

## Update repository
.PHONY: update
update:
	git fetch
	git merge --ff-only origin/master

## -- Cross Platform Bootstrap --

## Create bash symlinks
.PHONY: link
link:
	mkdir -p ~/dev
	ln -nsf $(CURDIR)/git/.gitconfig ~/.gitconfig
	ln -nsf $(CURDIR)/git/.gitignore_global ~/.gitignore_global
	ln -nsf $(CURDIR)/bash/.inputrc ~/.inputrc
	ln -nsf $(CURDIR)/bash/.curlrc ~/.curlrc
	ln -nsf $(CURDIR)/bash/.bashrc ~/.bashrc
	ln -nsf $(CURDIR)/bash/.bash_profile ~/.bash_profile
	mkdir -p ~/.gnupg
	ln -nsf $(CURDIR)/gnupg/gpg.conf ~/.gnupg/gpg.conf
	ln -nsf $(CURDIR)/gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
	ln -nsf $(CURDIR)/bash/.editorconfig ~/.editorconfig
	ln -nsf $(CURDIR)/bash/.ignore ~/.ignore

## Install dependencies
.PHONY: install-deps
install-deps: $(OS)

## Installs nvm
.PHONY: nvm
nvm:
	git clone https://github.com/creationix/nvm.git ~/.nvm
	cd ~/.nvm && \
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

## Install rvm
.PHONY: rvm
rvm:
	sudo apt-add-repository -y ppa:rael-gc/rvm
	sudo apt-get update
	sudo apt-get install rvm -y

## Add frequently used gpg keys
.PHONY: add-gpg-keys
add-gpg-keys:
	gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB



## -- Macos Bootstrap --

## Install macos dependencies
.PHONY: macos
macos: homebrew

## Install homebrew and child applications on macos. Notably,
## - bash 4.3 and adds to /etc/shells
## - macos applications  
## - fonts
.PHONY: homebrew
homebrew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew bundle --file=$(CURDIR)/macos/.Brewfile || true
	echo /usr/local/bin/bash | sudo tee -a /etc/shells
	chsh -s /usr/local/bin/bash

## Apply default macos settings
.PHONY: mac_defaults
mac_defaults:
	bash $(CURDIR)/macos/defaults.sh





## -- Linux Bootstrap --

## Update repositories, upgrade existing packages and install linux dependencies
.PHONY: linux
linux: apt-upgrade apt-install set-timezone link

## Install linux packages
.PHONY: apt-install
apt-install: apt-update	install-ubuntu-packages neovim keybase docker

## Install packages from packages.ubuntu.com
.PHONY: install-ubuntu-packages
install-ubuntu-packages:
	cat $(CURDIR)/ubuntu/apt.txt | xargs sudo apt-get install -y

## Install keybase
.PHONY: keybase
keybase:
	cd /tmp && \
	curl -O https://prerelease.keybase.io/keybase_amd64.deb && \
	sudo dpkg -i keybase_amd64.deb || true && \
	sudo apt-get install -f -y && \
	run_keybase && \
	rm keybase_amd64.deb

## Install neovim
.PHONY: neovim
neovim:
	sudo add-apt-repository ppa:neovim-ppa/stable -y
	sudo apt-get update
	sudo apt-get install neovim -y
	sudo chown -R "$$(whoami):$$(whoami)" ~/.local/share/nvim/ # Fix for inappropriate permissions

## Install docker and docker-compose
.PHONY: docker
docker: apt-update
	sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $$(lsb_release -cs) \
   stable"
	sudo apt-get update
	sudo apt-get install docker-ce -y
	sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose

## Upgrade linux packages
.PHONY: apt-upgrade
apt-upgrade: apt-update
	sudo apt-get upgrade -y

## Update package lists
.PHONY: apt-update
apt-update:
	sudo apt-get update

## Sets timezone to UTC
.PHONY: set-timezone
set-timezone:
	sudo timedatectl set-timezone UTC

## Provisions and hardens root user
## - Creates a new user and copies SSH public key
## - Hardens server and disable root user
.PHONY: provision-root
provision-root: provision-user harden

## Provision a new non-root user
## - Prompts for new user name and password
## - Adds user to sudo group
## - Copies root authorised_keys
.PHONY: provision-user
provision-user:
	@read -p "Enter new username: " NEW_USER && \
	adduser $$NEW_USER && \
	sudo usermod -a -G sudo $$NEW_USER && \
	sudo mkdir -p "/home/$${NEW_USER}/.ssh" && \
	sudo cp /root/.ssh/authorized_keys "/home/$${NEW_USER}/.ssh/authorized_keys" && \
	sudo chown -R "$${NEW_USER}:$${NEW_USER}" "/home/$${NEW_USER}/.ssh" && \
	sudo chmod 700 "/home/$${NEW_USER}/.ssh" && \
	sudo chmod 600 "/home/$${NEW_USER}/.ssh/authorized_keys" 

## Hardens network setup
## - Reconfigures sshd_config
## - No root ssh
## - fail2ban
## - ipv4 ipv6 iptables setup
.PHONY: harden
harden:
	sudo cp $(CURDIR)/ubuntu/etc/sshd_config /etc/ssh/sshd_config
	sudo chown root:root /etc/ssh/sshd_config
	sudo chmod 644 /etc/ssh/sshd_config
	sudo ssh-keygen -A
	sudo systemctl restart ssh.service
	sudo apt-get install fail2ban -y
	sudo cp $(CURDIR)/ubuntu/etc/ipv4.firewall /etc/ipv4.firewall
	sudo cp $(CURDIR)/ubuntu/etc/ipv6.firewall /etc/ipv6.firewall
	sudo cp $(CURDIR)/ubuntu/etc/load-firewall /etc/network/if-up.d/load-firewall
	sudo chmod +x /etc/network/if-up.d/load-firewall
	sudo /etc/network/if-up.d/load-firewall
	sudo apt-get install unattended-upgrades -y

## -- Misc --

## How to use Makefile
.PHONY: help
help:
	@printf "Usage\n";

	@awk '{ \
			if ($$0 ~ /^.PHONY: [a-zA-Z\-\_0-9]+$$/) { \
				helpCommand = substr($$0, index($$0, ":") + 2); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^[a-zA-Z\-\_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":")); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 3); \
				} else { \
					helpMessage = substr($$0, 3); \
				} \
			} else { \
				if (helpMessage) { \
					print "\n                     "helpMessage"\n" \
				} \
				helpMessage = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)

