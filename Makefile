APP=hello
VERSION=0.1.0

TARGETDIR=target
BUILDDIR=build
TARGETBIN=${APP}-v${VERSION}

COMMIT_ID:=$(shell git rev-parse HEAD)
LDFLAGS=-ldflags "-linkmode external -extldflags -static -X main.Version=${VERSION} -X main.CommitID=${COMMIT_ID}"

UID_NR:=$(shell id -u)
GID_NR:=$(shell id -g)
PASSWD=$(shell pwd)/${BUILDDIR}/passwd
HOMEDIR=$(shell pwd)/${BUILDDIR}/home

GITHUB_USER=sdorra
GITHUB_REPO=release-test

.PHONY: default
default: $(TARGETDIR)/$(TARGETBIN) $(TARGETDIR)/$(TARGETBIN).sha256sum $(TARGETDIR)/$(TARGETBIN).asc

$(TARGETDIR):
	mkdir ${TARGETDIR}

$(BUILDDIR):
	mkdir ${BUILDDIR}

$(PASSWD): $(BUILDDIR)
	echo "${USER}:x:${UID_NR}:${GID_NR}:${USER}:/home/${USER}:/bin/bash" > "${PASSWD}"

$(HOMEDIR): $(BUILDDIR)
	mkdir $(HOMEDIR)

$(TARGETDIR)/$(TARGETBIN): $(PASSWD) $(HOMEDIR) $(TARGETDIR)
	docker run --rm -ti \
	 -e GOOS=linux \
	 -e GOARCH=amd64 \
	 -u "${UID_NR}:${GID_NR}" \
	 -v ${PASSWD}:/etc/passwd:ro \
	 -v ${HOMEDIR}:/home/${USER} \
	 -v $(shell pwd):/go/src/github.com/cloudogu/${APP} \
	 -w /go/src/github.com/cloudogu/${APP} \
	 golang:1.10.1 \
	 go build -a -tags netgo ${LDFLAGS} -installsuffix cgo -o $(TARGETDIR)/$(TARGETBIN)

$(TARGETDIR)/$(TARGETBIN).sha256sum:
	cd ${TARGETDIR}; shasum -a 256 ${TARGETBIN} > ${TARGETBIN}.sha256sum

$(TARGETDIR)/$(TARGETBIN).asc:
	gpg --detach-sign -o ${TARGETDIR}/${TARGETBIN}.asc ${TARGETDIR}/${TARGETBIN}

.PHONY: tag
tag:
	git tag -s -m "released version ${VERSION}" v${VERSION}

.PHONY: push
push:
	git push origin master --tags

.PHONY: release
release: default tag push
	github-release release \
		--user ${GITHUB_USER} \
		--repo ${GITHUB_REPO} \
		--tag v${VERSION} \
		--name v${VERSION} \
		--description "release version ${VERSION}"

	github-release upload \
		--user ${GITHUB_USER} \
		--repo ${GITHUB_REPO} \
		--tag v${VERSION} \
		--name ${TARGETBIN} \
		--file ${TARGETDIR}/${TARGETBIN}

	github-release upload \
		--user ${GITHUB_USER} \
		--repo ${GITHUB_REPO} \
		--tag v${VERSION} \
		--name ${TARGETBIN}.sha256sum \
		--file ${TARGETDIR}/${TARGETBIN}.sha256sum

	github-release upload \
		--user ${GITHUB_USER} \
		--repo ${GITHUB_REPO} \
		--tag v${VERSION} \
		--name ${TARGETBIN}.asc \
		--file ${TARGETDIR}/${TARGETBIN}.asc

.PHONY: clean
clean:
	rm -rf $(TARGETDIR)
	rm -rf $(BUILDDIR)
