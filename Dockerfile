FROM golang:1.24.2-bookworm

RUN set -eu \
  && apt update \
  && apt install -y libgpgme-dev libassuan-dev libbtrfs-dev pkg-config

ENV DISABLE_DOCS=1
ENV CGO_ENABLED=0
ENV BUILDTAGS=containers_image_openpgp

RUN set -eu \
  && git clone https://github.com/containers/skopeo $GOPATH/src/github.com/containers/skopeo \
  && cd $GOPATH/src/github.com/containers/skopeo && make bin/skopeo \
  && cp $GOPATH/src/github.com/containers/skopeo/bin/skopeo /usr/local/bin

CMD ["sh", "-c", "mkdir -p /dist && cp $GOPATH/src/github.com/containers/skopeo/bin/skopeo /dist/"]
