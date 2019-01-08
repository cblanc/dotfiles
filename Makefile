UNAME := $(shell uname -s)

ifeq ($(UNAME), Darwin)
  OS := macos
else ifeq ($(UNAME), Linux)
  OS := linux
endif

.PHONY: init
init: install-deps

.PHONY: install-deps
install-deps: $(OS)

.PHONY: macos
macos: brew

.PHONY: brew
brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew bundle --file=$(CURDIR)/macos/.Brewfile
