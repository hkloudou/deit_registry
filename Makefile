include ../includes.mk

COMPONENT = registry
IMAGE = $(IMAGE_PREFIX)$(COMPONENT):$(BUILD_TAG)
DEV_IMAGE = $(REGISTRY)$(IMAGE)

SHELL_SCRIPTS = $(shell find "." -name '*.sh') $(wildcard bin/*)
git:
	-git add .
	-git commit -m 'build auto commit'
	-git tag -f 0.1.0
	-git push origin master -f --tags
build: check-docker
	#build confd
	#hkloudou/gobuilder:alpine3.7-go1.10.1
	@docker run --rm --privileged=true -w /go/src/code/ hkloudou/gobuilder:alpine3.7-go1.10.1 go version
	@docker run --rm --privileged=true -v $(GOPATH)/src/:/go/src/ -v $(PWD)/rootfs/usr/local/bin/:/go/bin/ -w /code/ hkloudou/gobuilder:alpine3.7-go1.10.1 go build -ldflags "-X main.GitSHA=${GIT_SHA}" -o /go/bin/confd github.com/hkloudou/confd
	
	@docker run --rm --privileged=true -v $(GOPATH)/src/:/go/src/ -v $(PWD)/rootfs/usr/local/bin/:/go/bin/ -w /code/ hkloudou/gobuilder:alpine3.7-go1.10.1 go build -ldflags "-X main.GitSHA=${GIT_SHA}" -o /go/bin/etcdctl github.com/hkloudou/etcd/etcdctl
	
	
	

	docker build -t $(IMAGE) .

	#rm rootfs/bin/boot
	rm rootfs/usr/local/bin/confd
	rm rootfs/usr/local/bin/etcdctl
clean: check-docker check-registry
	docker rmi $(IMAGE)

full-clean: check-docker check-registry
	docker images -q $(IMAGE_PREFIX)$(COMPONENT) | xargs docker rmi -f

install: check-deisctl
	deisctl scale $(COMPONENT)=1

uninstall: check-deisctl
	deisctl scale $(COMPONENT)=0

start: check-deisctl
	deisctl start $(COMPONENT)@*

stop: check-deisctl
	deisctl stop $(COMPONENT)@*

restart: stop start

run: install start

dev-release: push set-image

push: check-registry
	docker tag $(IMAGE) $(DEV_IMAGE)
	docker push $(DEV_IMAGE)

set-image: check-deisctl
	deisctl config $(COMPONENT) set image=$(DEV_IMAGE)

release:
	docker push $(IMAGE)

deploy: build dev-release restart

test: test-style test-unit test-functional

test-functional:
	@$(MAKE) -C ../tests/ mock-store
	@$(MAKE) -C ../tests/ test-etcd
	GOPATH=`cd ../tests/ && godep path`:$(GOPATH) go test -v ./tests/...

test-style:
	shellcheck $(SHELL_SCRIPTS)

test-unit:
	@echo no unit tests
