.DEFAULT_GOAL := help

DOTFILES_DIR := $(shell echo $(HOME)/dotfiles)
UNAME := $(shell uname -s)

## Help message
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

ifeq ($(UNAME), Darwin)
  OS := macos
else ifeq ($(UNAME), Linux)
  OS := linux
endif

## Update repository
.PHONY: update
update:
	git pull origin master

## -- Cross Platform Bootstrap --

## Create bash symlinks
.PHONY: link
link:
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

## Bootstrap new host
.PHONY: init
init: install-deps link

## Install dependencies
.PHONY: install-deps
install-deps: $(OS)

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
apt-install:	
	sudo apt-get update
	cat $(CURDIR)/ubuntu/apt.txt | xargs sudo apt-get install -y

## Upgrade linux packages
.PHONY: apt-upgrade
apt-upgrade:
	sudo apt-get update
	sudo apt-get upgrade -y

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
	@read -p "Enter new username:" NEW_USER && \
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
	sudo apt-get install fail2ban
	sudo cp $(CURDIR)/ubuntu/etc/ipv4.firewall /etc/ipv4.firewall
	sudo cp $(CURDIR)/ubuntu/etc/ipv6.firewall /etc/ipv6.firewall
	sudo cp $(CURDIR)/ubuntu/etc/load-firewall /etc/network/if-up.d/load-firewall
	sudo chmod +x /etc/network/if-up.d/load-firewall
	sudo /etc/network/if-up.d/load-firewall
	sudo apt-get install unattended-upgrades

