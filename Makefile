SHELL := /usr/bin/env bash -o errexit -o pipefail -o nounset

POLICY_FILES = policies.lab.yaml policies.stg.yaml policies.prod.yaml

#
##@ Available Commands
#

.PHONY: help
help: ## Print this help message
	@printf 'Lint and test everything in a GitOps repository.\n\n Find more information at: %s\n' 'https://hackmd.io/@104ContainerizationProject/BJFFt1_hK/%2F7ORj5fu0Qdyco27ZJW2Z5A'
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make [command]\033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s:\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: lint
lint: lint-yaml install.helm install.goam install.gator $(POLICY_FILES) ## Run all linters
	@goam --version
	goam app lint -p policies.{env}.yaml -v

.PHONY: lint-yaml
lint-yaml: install.yamllint ## Run the YAML lint
	@yamllint -v
	yamllint .

.PHONY: lint-appset
lint-appset: install.goam install.helm ## Run the ApplicationSet lint
	@goam --version
	goam app lint-appsets -v

.PHONY: lint-chart
lint-chart: install.goam install.helm ## Run the Helm chart lint
	@goam --version
	goam chart lint -v .

$(POLICY_FILES):
ifndef GITHUB_PAT
	$(error Please set environment variable GITHUB_PAT to download policy file)
endif
	@echo "Downloading '$@' file"
	@curl -fsS -H "Authorization: token ${GITHUB_PAT}" -o "$@" "https://raw.githubusercontent.com/104corp/k8s-policies/main/deploy/$@"

.PHONY: test-policy
test-policy: install.goam install.gator $(POLICY_FILES) ## Run the policy tests
	@gator --version
	goam policy test . -p policies.{env}.yaml -v

.PHONY: scan-secrets
scan-secrets: install.gitleaks ## Scan secrets in code
	@echo -n "gitleaks version: " && gitleaks version
	gitleaks detect --no-git

## Dependency Tools

.PHONY: install.gator
install.gator:
ifeq (, $(shell which gator))
	$(error The 'gator' command not found, install it from https://github.com/open-policy-agent/gatekeeper/releases or via 'brew install gator')
endif

.PHONY: install.gitleaks
install.gitleaks:
ifeq (, $(shell which gitleaks))
	$(error The 'gitleaks' command not found, install it from https://github.com/gitleaks/gitleaks or via 'brew install gitleaks')
endif

.PHONY: install.goam
install.goam:
ifeq (, $(shell which goam))
	$(error The 'goam' command not found, install it from https://github.com/104corp/goam)
endif

.PHONY: install.helm
install.helm:
ifeq (, $(shell which helm))
	$(error The 'helm' command not found, install it from https://helm.sh/docs/intro/install/ or via 'brew install helm')
endif

.PHONY: install.yamllint
install.yamllint:
ifeq (, $(shell which yamllint))
	$(error The 'yamllint' command not found, install it from https://github.com/adrienverge/yamllint or via 'brew install yamllint')
endif
