HOME_CONFIG := $(HOME)/.config

.PHONY: init
init: ## Sets up symlink
	mkdir -p "$(HOME_CONFIG)"
