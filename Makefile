VERSION := $(shell cat VERSION)
IMAGE ?= sixblack/acelink
DOCKER_BUILDKIT ?= 1
export DOCKER_BUILDKIT

.PHONY: docker docker-push dmg tag release

docker:
	# Build the Ace Stream engine image (amd64 only; runs via Rosetta/QEMU on Apple silicon)
	docker build --platform=linux/amd64 . --tag $(IMAGE):$(VERSION) --tag $(IMAGE):latest --progress=plain

docker-push: docker
	# Push the engine image (requires `docker login` as the image owner)
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest

dmg:
	# Build builds/Ace.Link.$(VERSION).dmg
	scripts/build-dmg.sh $(VERSION)

tag:
	# Tag the release; CI then builds the DMG, publishes the GitHub release and pushes the image
	git tag $(VERSION)
	git push origin $(VERSION)

release: dmg docker-push
