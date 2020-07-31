CURRENT_WORKING_DIR=$(shell pwd)
KUBESEAL_VERSION = v0.12.1
YQ_VERSION = 3.3.2

kubeseal:
	wget https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-darwin-amd64
	sudo install -m 755 kubeseal-darwin-amd64 /usr/local/bin/kubeseal
	rm -f kubeseal-darwin-amd64

k3d:
	brew install k3d

yq:
	wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_darwin_amd64
	sudo install -m 755 yq_darwin_amd64 /usr/local/bin/yq
	rm -f yq_darwin_amd64

init: k3d kubeseal yq

cluster:
	k3d cluster create kafka-gitops --servers 4

destroy:
	k3d cluster delete kafka-gitops

install-bitnami-secret-controller:
	kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.4/controller.yaml

install-flux: 
	./scripts/flux-init.sh

seal-%:
	./scripts/seal-secrets.sh $*

get-public-key:
ifndef ENV
	$(error ENV is not set.  Set it to indicate which environment to generate a key for)
endif
	kubeseal --fetch-cert > secrets/keys/$(ENV).crt

test-%:
	mkdir -p .test
	kustomize build environments/$* > .test/$*.yaml
	@echo
	@echo The output can be found at .test/$*.yaml