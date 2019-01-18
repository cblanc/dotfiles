DOTFILES_DIR := $(shell echo $(HOME)/dotfiles)
UNAME := $(shell uname -s)

ifeq ($(UNAME), Darwin)
  OS := macos
else ifeq ($(UNAME), Linux)
  OS := linux
endif

.PHONY: init
init: install-deps link

.PHONY: install-deps
install-deps: $(OS)

.PHONY: macos
macos: homebrew

.PHONY: homebrew
homebrew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew bundle --file=$(CURDIR)/macos/.Brewfile || true
	echo /usr/local/bin/bash | sudo tee -a /etc/shells # Use Bash 4.4 from homebrew
	chsh -s /usr/local/bin/bash

.PHONY: mac_defaults
mac_defaults:
	bash $(CURDIR)/macos/defaults.sh

.PHONY: linux
linux: apt-upgrade apt-install

.PHONY: apt-install
apt-install:	
	apt-get update
	cat $(CURDIR)/ubuntu/apt.txt | xargs sudo apt-get install -y

.PHONY: apt-upgrade
apt-upgrade:
	apt-get update
	apt-get upgrade -y

.PHONY: link
link:
	ln -nsf $(CURDIR)/git/.gitconfig ~/.gitconfig
	ln -nsf $(CURDIR)/git/.gitignore_global ~/.gitignore_global
	ln -nsf $(CURDIR)/bash/.inputrc ~/.inputrc
	ln -nsf $(CURDIR)/bash/.curlrc ~/.curlrc
	ln -nsf $(CURDIR)/bash/.bashrc ~/.bashrc
	mkdir -p ~/.gnupg
	ln -nsf $(CURDIR)/gnupg/gpg.conf ~/.gnupg/gpg.conf
	ln -nsf $(CURDIR)/gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
