CURRENT_DIR := $(shell pwd)
REPOS=ryda20
NAME=code-server
VER=lasted
TAG_NAME=$(REPOS)/$(NAME):$(VER)
TAG_NAME_S6=$(REPOS)/$(NAME):$(VER).s6


#--no-cache 
build:
	docker build -t $(TAG_NAME) -f Dockerfile --build-arg ssh_public_key="$(shell cat ~/.ssh/id_ed25519.pub)" .

build-pro: SHELL:=/bin/bash   # HERE: this is setting the shell for b only
build-pro:
	./Makefile.sh build_product "Dockerfile"
	

builds6:
	docker build -t $(TAG_NAME_S6) -f Dockerfile.S6 --build-arg ssh_public_key="$(shell cat ~/.ssh/id_ed25519.pub)" .
push:
	docker push $(TAG_NAME)

# # -v ~/gitlab/codeserver/product.json:/app/code-server/lib/vscode/product.json:ro 
run:
	docker run -it --rm \
	--name code-server \
	-v ~/gitlab:/config/workspace \
	-p 8080:8080 \
	-p 2222:22 \
	-e EPUID=99 \
	-e EPGID=100 \
	$(TAG_NAME)

runs6:
	docker run -it --rm \
	--name code-server \
	-v ~/gitlab:/config/workspace \
	-p 8080:8080 \
	-p 2222:22 \
	-e EPUID=99 \
	-e EPGID=100 \
	$(TAG_NAME_S6)
exec:
	docker exec -it code-server /bin/bash
execroot:
	docker exec -it -u root code-server /bin/bash