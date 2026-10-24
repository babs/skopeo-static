FROM golang:1.27.3-bookworm

RUN set -eu \
  && apt update \
  && apt install -y libgpgme-dev libassuan-dev libbtrfs-dev pkg-config

ENV DISABLE_DOCS=1
ENV CGO_ENABLED=0
ENV BUILDTAGS=containers_image_openpgp

# Move the commit pin to the v1.25.0 tag once upstream publishes it
ARG SKOPEO_VERSION="v1.25.0"
ARG SKOPEO_COMMIT="9eb82d9bf89fc984c877b9bc3f06127d4e159c7f"

RUN set -eu \
  && mkdir -p $GOPATH/src/github.com/containers/skopeo \
  && cd $GOPATH/src/github.com/containers/skopeo \
  && git init -q \
  && git fetch -q --depth 1 https://github.com/containers/skopeo "$SKOPEO_COMMIT" \
  && git checkout -q FETCH_HEAD \
  # Upstream Makefile forces -buildmode=pie on linux, which links a glibc interpreter
  && make bin/skopeo GO_DYN_FLAGS= \
  && readelf -lW bin/skopeo > /tmp/skopeo.phdr \
  && if grep -qE '^ +(INTERP|DYNAMIC) ' /tmp/skopeo.phdr; then echo 'bin/skopeo is not static' >&2; exit 1; fi \
  && if ! bin/skopeo --version | grep -qxF "skopeo version ${SKOPEO_VERSION#v} commit: $SKOPEO_COMMIT"; then echo "bin/skopeo is not $SKOPEO_VERSION ($SKOPEO_COMMIT)" >&2; exit 1; fi \
  && cp $GOPATH/src/github.com/containers/skopeo/bin/skopeo /usr/local/bin

CMD ["sh", "-c", "mkdir -p /dist && cp $GOPATH/src/github.com/containers/skopeo/bin/skopeo /dist/"]
