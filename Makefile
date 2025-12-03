SHELL := /bin/bash
TF ?= terraform
TFVARS ?= terraform.tfvars

.PHONY: interactive init plan apply destroy validate fmt clean

interactive:
	@bash scripts/interactive.sh

init:
	$(TF) init

plan: init
	$(TF) plan -var-file=$(TFVARS)

apply: init
	$(TF) apply -var-file=$(TFVARS)

destroy: init
	$(TF) destroy -var-file=$(TFVARS)

validate:
	$(TF) validate

fmt:
	$(TF) fmt

clean:
	rm -f tfplan $(TFVARS)
