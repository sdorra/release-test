APP=hello
VERSION=0.1.0

TARGETDIR=target
BUILDDIR=build

COMMIT_ID:=$(shell git rev-parse HEAD)
LDFLAGS=-ldflags "-linkmode external -extldflags -static -X main.Version=${VERSION} -X main.CommitID=${COMMIT_ID}"

UID_NR:=$(shell id -u)
GID_NR:=$(shell id -g)
PASSWD=$(shell pwd)/${BUILDDIR}/passwd
HOMEDIR=$(shell pwd)/${BUILDDIR}/home

.PHONY: default
default: $(TARGETDIR)/$(APP) $(TARGETDIR)/$(APP).sha256sum $(TARGETDIR)/$(APP).asc

$(TARGETDIR):
	mkdir ${TARGETDIR}

$(BUILDDIR):
	mkdir ${BUILDDIR}

$(PASSWD): $(BUILDDIR)
	echo "${USER}:x:${UID_NR}:${GID_NR}:${USER}:/home/${USER}:/bin/bash" > "${PASSWD}"

$(HOMEDIR): $(BUILDDIR)
	mkdir $(HOMEDIR)

$(TARGETDIR)/$(APP): $(PASSWD) $(HOMEDIR) $(TARGETDIR)
	docker run --rm -ti \
	 -e GOOS=linux \
	 -e GOARCH=amd64 \
	 -u "${UID_NR}:${GID_NR}" \
	 -v ${PASSWD}:/etc/passwd:ro \
	 -v ${HOMEDIR}:/home/${USER} \
	 -v $(shell pwd):/go/src/github.com/cloudogu/${APP} \
	 -w /go/src/github.com/cloudogu/${APP} \
	 golang:1.10.1 \
	 go build -a -tags netgo ${LDFLAGS} -installsuffix cgo -o $(TARGETDIR)/$(APP)

$(TARGETDIR)/$(APP).sha256sum:
	shasum -a 256 $(TARGETDIR)/$(APP) > $(TARGETDIR)/$(APP).sha256sum

$(TARGETDIR)/$(APP).asc:
	gpg --detach-sign -o $(TARGETDIR)/$(APP).asc $(TARGETDIR)/$(APP)

.PHONY: clean
clean:
	rm -rf $(TARGETDIR)
	rm -rf $(BUILDDIR)
