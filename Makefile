.PHONY: help tofu-init tofu-fmt tofu-validate tofu-plan tofu-apply tofu-destroy ansible-check ansible-apply test

TOFU_DIR := tofu
INVENTORY := ansible/inventory/hosts.yml
PLAYBOOK := ansible/playbooks/site.yml

help:
	@echo "Pushlane targets: tofu-init, tofu-plan, tofu-apply, ansible-check, ansible-apply, test"

tofu-init:
	tofu -chdir=$(TOFU_DIR) init

tofu-fmt:
	tofu -chdir=$(TOFU_DIR) fmt -recursive

tofu-validate: tofu-fmt
	tofu -chdir=$(TOFU_DIR) validate

tofu-plan: tofu-validate
	tofu -chdir=$(TOFU_DIR) plan -out=pushlane.tfplan

tofu-apply:
	tofu -chdir=$(TOFU_DIR) apply pushlane.tfplan

tofu-destroy:
	tofu -chdir=$(TOFU_DIR) plan -destroy

ansible-check:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff

ansible-apply:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

test:
	python -m pytest apps/demo-api/tests

