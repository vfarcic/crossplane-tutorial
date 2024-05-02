.DEFAULT_GOAL := help

#--------
# The following can be removed if you don't need to include variables from a 
# .env file
#--------

ENV_PREFIX ?= ./
ENV_FILE := $(wildcard $(ENV_PREFIX)/.env)

ifeq ($(strip $(ENV_FILE)),)
$(info $(ENV_PREFIX)/.env file not found, skipping inclusion)
else
include $(ENV_PREFIX)/.env
export
endif

#-------
##@ help
#-------

# based on "https://gist.github.com/prwhite/8168133?permalink_comment_id=4260260#gistcomment-4260260"
help: ## Display this help. (Default)
	@grep -hE '^(##@|[A-Za-z0-9_ \-]*?:.*##).*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; /^##@/ {print "\n" substr($$0, 5)} /^[A-Za-z0-9_ \-]*?:.*##/ {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

help-sort: ## Display alphabetized version of help (no section headings).
	@grep -hE '^[A-Za-z0-9_ \-]*?:.*##.*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; /^[A-Za-z0-9_ \-]*?:.*##/ {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

HELP_TARGETS_PATTERN ?= test
help-targets: ## Print commands for all targets matching a given pattern. eval "$(make help-targets HELP_TARGETS_PATTERN=test | sed 's/\x1b\[[0-9;]*m//g')"
	@make help-sort | awk '{print $$1}' | grep '$(HELP_TARGETS_PATTERN)' | xargs -I {} printf "printf '___\n\n{}:\n\n'\nmake -n {}\nprintf '\n'\n"


#--------------------------------------
##@ setup local development environment
#--------------------------------------

uninstall-nix: ## Uninstall nix.
	(cat /nix/receipt.json && \
	/nix/nix-installer uninstall) || echo "nix not found, skipping uninstall"

install-nix: ## Install nix. Check script before execution: https://install.determinate.systems/nix.
install-nix: uninstall-nix
	@which nix > /dev/null || \
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

install-direnv: ## Install direnv to `/usr/local/bin`. Check script before execution: https://direnv.net/.
	@which direnv > /dev/null || \
	(curl -sfL https://direnv.net/install.sh | bash && \
	sudo install -c -m 0755 direnv /usr/local/bin && \
	rm -f ./direnv)
	@echo "See https://direnv.net/docs/hook.html for instructions to update your shell profile to use direnv."

setup-dev: ## Setup nix development environment with direnv and nix.
setup-dev: install-direnv install-nix
	@. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
	echo "trusted-users = root $$USER" | sudo tee -a /etc/nix/nix.conf && \
	sudo pkill nix-daemon
