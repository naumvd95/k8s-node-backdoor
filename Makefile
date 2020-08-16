GIT_HOST = github.com
PWD := $(shell pwd)
GOPATH_DEFAULT := $(shell go env GOPATH)
export GOPATH ?= $(GOPATH_DEFAULT)
GOBIN_DEFAULT := $(GOPATH)/bin
export GOBIN ?= $(GOBIN_DEFAULT)
PATH := $(PATH):$(PWD)/bin:$(GOBIN)
VERBOSE :=
ifndef VERBOSE
GOFLAGS   :=
DEPFLAGS  :=
else
GOFLAGS   := "-v"
DEPFLAGS  := "-v"
endif
GOOS ?= $(shell go env GOOS)

$(GOBIN):
	echo "create gobin"
	mkdir -p $(GOBIN)
work: $(GOBIN)

#go tools
HAS_DEP := $(shell command -v dep;)
depend: work
ifndef HAS_DEP
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
endif
	dep ensure $(DEPFLAGS)

depend-update:
	dep ensure -update $(DEPFLAGS)

#versioning
GIT_COMMIT=$(shell git rev-parse HEAD)
BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
APP_VERSION=$(shell git rev-parse --short=7 HEAD)
LDFLAGS   = "-w -s -X 'github.com/naumvd95/k8s-node-backdoor/pkg/version.appVersion=${APP_VERSION}'-X 'github.com/naumvd95/k8s-node-backdoor/pkg/version.gitCommit=${GIT_COMMIT}' -X 'github.com/naumvd95/k8s-node-backdoor/pkg/version.buildDate=${BUILD_DATE}'"
 


# binaries
nodebackdoor:
	GOOS=$(GOOS) go build $(GOFLAGS) \
		-ldflags $(LDFLAGS) \
		-o bin/nodebackdoor \
		cmd/main.go

# images
REGISTRY:= vnaumov
SSH_PUBKEY_FILEPATH:= hack/ssh/admin_backdoor.pub
nodebackdoor-image-name:
	@echo $(REGISTRY)/k8s-node-backdoor:$(APP_VERSION)
nodebackdoor-image: nodebackdoor
ifeq ($(GOOS),linux)
	TMPDIR="$$(mktemp -d)"; \
	cleanup () { rm -rf "$${TMPDIR}"; }; \
	trap cleanup EXIT; \
	cp $(SSH_PUBKEY_FILEPATH) "$${TMPDIR}/id_rsa.pub"; \
	cp bin/nodebackdoor "$${TMPDIR}"; \
	docker build -t $(REGISTRY)/k8s-node-backdoor:$(APP_VERSION) -f Dockerfile "$${TMPDIR}"
else
	$(error Please set GOOS=linux for building the image)
endif

DOCKER_USERNAME:=vnaumov
DOCKER_PASSWORD:=
image-push:
	@echo "push images to $(REGISTRY)"
	docker login -u="$(DOCKER_USERNAME)" -p="$(DOCKER_PASSWORD)"
	docker push $(REGISTRY)/k8s-node-backdoor:$(APP_VERSION)

# infra image ops
# TODO manage at least 2 tags stable/latest
INFRA_IMAGE:= $(REGISTRY)/go-infra-ops:latest
infra-image:
	docker build -t $(INFRA_IMAGE) -f hack/Dockerfile .

# linters
dockerized-lint:
	docker run --rm \
	-v $(PWD):/go/src/github.com/naumvd95/k8s-node-backdoor \
	-w=/go/src/github.com/naumvd95/k8s-node-backdoor \
	$(INFRA_IMAGE) make VERBOSE=1 lint

# local linter
lint:
	if golangci-lint run -v ./...; then \
	  :; \
	else \
	  code=$$?; \
	  echo "Looks like golangci-lint failed. You can try autofixes with 'make fix'."; \
	  exit $$code; \
	fi

# DEV k8s env
.PHONY: apply-tf-boilerplate destroy-tf-boilerplate ansible-k8s
AWS_PROFILE:=
apply-tf-boilerplate:
	cd kubernetes-environment/terraform-cluster-boilerplate; \
	terraform apply -var aws_profile=$(AWS_PROFILE) -auto-approve && \
	cd -

destroy-tf-boilerplate:
	cd kubernetes-environment/terraform-cluster-boilerplate; \
	terraform destroy -var aws_profile=$(AWS_PROFILE) && \
	cd -

# sleep a little bit, due aws public ip initialization
ansible-k8s: apply-tf-boilerplate
	sleep 20
	ansible-playbook kubernetes-environment/ansible/site.yaml \
	-i kubernetes-environment/terraform-cluster-boilerplate/ansible-hosts.ini

.PHONY: fix
fix:
	golangci-lint run -v --fix ./...
