# Directory definitions
CFN_DIR := cloudformation
VENV_DIR := venv

# CloudFormation templates, sources and tests
TEMPLATES := $(wildcard $(CFN_DIR)/*.yml)

# PIP download endpoint
PIP_ENDPOINT := https://bootstrap.pypa.io/get-pip.py

# Activate Command
# Not neccessary for Travis CI
ifdef TRAVIS
	ACTIVATE := true
else
	ACTIVATE := . $(VENV_DIR)/bin/activate
endif

# AWS CLI Command
AWS := $(shell which aws)

# AWS Deploy Region
REGION := us-east-2

# Remove internal rules
.SUFFIXES:

# Default target
.PHONY: all
all: $(VENV_DIR) lint validate

# Create the virtual environment
$(VENV_DIR):
	python3 -m venv --without-pip venv
	$(ACTIVATE) && curl -sS $(PIP_ENDPOINT) | python
	$(ACTIVATE) && pip install -r requirements.dev

# Install only required for Travis CI
.PHONY: install
install:
	pip install -r requirements.dev
	pip install --upgrade awscli

# Lint CloudFormation templates
.PHONY: lint
lint: $(TEMPLATES)
	$(ACTIVATE) && yamllint $^

# Validate CloudFormation templates
.PHONY: validate
validate: $(TEMPLATES)
	$(foreach FILE, $^, $(AWS) cloudformation --region $(REGION) validate-template --template-body file://$(FILE);)

# Sync to S3
.PHONY: sync
sync: $(TEMPLATES)
	$(AWS) s3 sync --exclude '*' --include '*.yml' $(CFN_DIR)/. s3://${BUCKET}

# Clean the workspace
.PHONY: clean
clean:
	-rm -rf $(VENV_DIR)
