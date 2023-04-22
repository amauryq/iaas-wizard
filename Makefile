.PHONY: tf-fmt tf-init tf-apply tf-apply-dns tf-destroy help
.DEFAULT_GOAL := help

TF_PARAMS = -lock=false -input=false -auto-approve

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help: ## print this list
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

MODULES = $(shell ls modules/)

tf-fmt: ## format terraform code
	$(foreach module, $(MODULES), terraform -chdir="modules/$(module)" fmt;)

tf-init: tf-fmt ## init terraform backend configuration and required providers and modules
	terraform init -upgrade -reconfigure -backend-config="bucket=$(TF_BKND_GCS_BUCKET)" -backend-config="prefix=$(TF_BKND_GCS_PREFIX)"

tf-plan: tf-fmt
	terraform plan

tf-apply: tf-fmt ## apply the terraform configuration for creating pod's resources and after create dns entries for mig managed vms
	terraform apply $(TF_PARAMS)
	
tf-destroy: tf-fmt ## destroy the all the terraform resources
	terraform destroy $(TF_PARAMS)
