.DEFAULT_GOAL := help
VERSION := $(shell date +%Y.%m.%d)

.PHONY: virtualbox
virtualbox: ## build virtualbox
	rm -rf output-vagrant
	packer build -var provider=virtualbox -var version=$(VERSION) -on-error=ask packer.json

.PHONY: parallels
parallels: ## build parallels
	rm -rf output-vagrant
	packer build -var provider=parallels -var version=$(VERSION) -on-error=ask packer.json

.PHONY: test
test: ## run tests
	docker run --rm -it \
	  -v $(PWD):/home/molecule/working:ro \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-w /home/molecule/working \
		quay.io/ansible/molecule:3.0.8 \
		molecule test

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
