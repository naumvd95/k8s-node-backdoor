GIT_HOST = github.com
GOPATH_DEFAULT := $(shell go env GOPATH)
export GOPATH ?= $(GOPATH_DEFAULT)
GOBIN_DEFAULT := $(GOPATH)/bin
export GOBIN ?= $(GOBIN_DEFAULT)
VERBOSE :=
ifndef VERBOSE
GOFLAGS   :=
DEPFLAGS  :=
else
GOFLAGS   := "-v"
DEPFLAGS  := "-v"
endif
GOOS ?= $(shell go env GOOS)

#go tools
HAS_DEP := $(shell command -v dep;)
depend:
ifndef HAS_DEP
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
endif
	dep ensure $(DEPFLAGS)

depend-update:
	dep ensure -update $(DEPFLAGS)

#versioning
GIT_COMMIT=$(shell git rev-parse HEAD)
BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
APP_VERSION=$(shell git describe --tags --first-parent)
LDFLAGS   = "-w -s -X 'github.com/k8s-node-backdoor/pkg/version.appVersion=${APP_VERSION}'-X 'github.com/k8s-node-backdoor/pkg/version.gitCommit=${GIT_COMMIT}' -X 'github.com/k8s-node-backdoor/pkg/version.buildDate=${BUILD_DATE}'"
 


# binaries
nodebackdoor:
	GOOS=$(GOOS) go build $(GOFLAGS) \
		-ldflags $(LDFLAGS) \
		-o bin/nodebackdoor \
		cmd/main.go

# images
image-context-dir:
	mkdir -p image-context
REGISTRY:= vnaumov
SSH_PUBKEY_FILEPATH:= ~/.ssh/id_rsa.pub
nodebackdoor-image-name:
	@echo $(REGISTRY)/k8s-node-backdoor:$(APP_VERSION)
nodebackdoor-image: nodebackdoor image-context-dir
ifeq ($(GOOS),linux)
	cp $(SSH_PUBKEY_FILEPATH) image-context/id_rsa.pub 
	cp bin/nodebackdoor entrypoint.sh image-context
	docker build -t $(REGISTRY)/k8s-node-backdoor:$(APP_VERSION) -f Dockerfile image-context
else
	$(error Please set GOOS=linux for building the image)
endif

DOCKER_USERNAME:=vnaumov
DOCKER_PASSWORD:=
image-push:
	@echo "push images to $(REGISTRY)"
	docker login -u="$(DOCKER_USERNAME)" -p="$(DOCKER_PASSWORD)"
	docker push $(REGISTRY)/k8s-node-backdoor:$(APP_VERSION)

# codelint
lint:
	if golangci-lint run -v ./...; then \
	  :; \
	else \
	  code=$$?; \
	  echo "Looks like golangci-lint failed. You can try autofixes with 'make fix'."; \
	  exit $$code; \
	fi

.PHONY: fix
fix:
	golangci-lint run -v --fix ./...
