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
linux: apt-upgrade apt-install

## Install linux packages
.PHONY: apt-install
apt-install:	
	apt-get update
	cat $(CURDIR)/ubuntu/apt.txt | xargs sudo apt-get install -y

## Upgrade linux packages
.PHONY: apt-upgrade
apt-upgrade:
	apt-get update
	apt-get upgrade -y

