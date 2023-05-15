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

# docker related commands

# Process for build and test your container images locally, then you can upload it to the Artifact Registry (AR) repo
# Prereqs: Docker daemon should be up and running locally in your workstation

REGION = us-east1

APP = wireguard
VERSION = 0.1.0
APP_FOLDER = docker/$(APP)

LOCAL_PORT = 8080
PORT = 80

DOCKER_REGISTRY = $(REGION)-docker.pkg.dev
DOCKER_REPO = linuxserver
DOCKER_TAG = $(VERSION)

DOCKER_URL = $(DOCKER_REGISTRY)/$(PROJECT_ID)/$(DOCKER_REPO)
DOCKER_IMAGE_URL = $(DOCKER_URL)/$(APP)

docker-clean: ## clean old terminated not used docker images
	docker rm $$(docker ps -a -q) || true
	docker rmi $$(docker images | grep '^<none>' | awk '{print $3}')  || true
	docker rmi $$(sudo docker images --filter "dangling=true" -q --no-trunc) || true
	docker rmi $(DOCKER_IMAGE_URL):latest || true
	docker rmi $(DOCKER_IMAGE_URL):$(DOCKER_TAG) || true

docker-build: docker-clean ## build app using Dockerfile
	cd $(APP_FOLDER) && docker build --label version=$(DOCKER_TAG) --build-arg APP_VERSION=$(VERSION) -t $(DOCKER_IMAGE_URL):latest .
	docker tag $(DOCKER_IMAGE_URL):latest $(DOCKER_IMAGE_URL):$(DOCKER_TAG)

docker-run: docker-build ## run app inside docker container
	docker run --name $(APP) --rm -p $(LOCAL_PORT):$(PORT) $(DOCKER_IMAGE_URL):latest
# 	docker inspect $(APP) --format='{{.State.ExitCode}}'

docker-creds:
	gcloud auth configure-docker $(DOCKER_REGISTRY)
#	gcloud artifacts repositories list --project $(PROJECT_ID)

docker-login:
	cat $(GOOGLE_APPLICATION_CREDENTIALS) | docker login https://$(DOCKER_URL) -u _json_key --password-stdin

docker-push: docker-build docker-creds docker-login ## push image to the docker registry
	docker push $(DOCKER_IMAGE_URL):latest
	docker push $(DOCKER_IMAGE_URL):$(DOCKER_TAG)

# terraform related commands

MODULES = $(shell ls modules/)

tf-fmt: ## format terraform code
	$(foreach module, $(MODULES), terraform -chdir="modules/$(module)" fmt;)

tf-init: tf-fmt ## init terraform backend configuration and required providers and modules
	terraform init -reconfigure -backend-config="bucket=$(TF_BKND_GCS_BUCKET)" -backend-config="prefix=$(TF_BKND_GCS_PREFIX)"

tf-plan: tf-fmt
	terraform plan -out tfplan

tf-apply: tf-fmt ## apply the terraform configuration for creating resources
	terraform apply $(TF_PARAMS)
	
tf-destroy: tf-fmt ## destroy the all the terraform resources
	terraform destroy $(TF_PARAMS)
