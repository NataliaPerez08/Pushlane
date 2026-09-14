.PHONY: help tofu-init tofu-fmt tofu-validate tofu-plan tofu-apply tofu-destroy ansible-check ansible-apply test

TOFU_DIR := tofu
ANSIBLE_DIR := ansible
INVENTORY := inventory/hosts.yml
PLAYBOOK := playbooks/site.yml
# Uso: make ansible-apply ANSIBLE_EXTRA_ARGS="--ask-vault-pass"
ANSIBLE_EXTRA_ARGS ?=

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

# ansible.cfg (roles_path, inventario por defecto) solo se carga si
# ansible-playbook se ejecuta desde $(ANSIBLE_DIR).
ansible-check:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff $(ANSIBLE_EXTRA_ARGS)

ansible-apply:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK) $(ANSIBLE_EXTRA_ARGS)

test:
	cd apps/demo-api && python -m pytest tests

