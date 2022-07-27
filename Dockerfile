FROM golang:1.18.2-alpine as builder

ENV GODEBUG netdns=cgo

ARG checkout="master"
ARG git_url="https://github.com/lightningnetwork/lnd"


RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
    gcc \
&&  git clone $git_url /go/src/github.com/lightningnetwork/lnd \
&&  cd /go/src/github.com/lightningnetwork/lnd \
&&  git checkout $checkout \
&&  make release-install


FROM alpine as final


VOLUME /root/.lnd

RUN apk --no-cache add \
    bash \
    jq \
    ca-certificates \
    gnupg \
    curl


COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/
COPY --from=builder /go/src/github.com/lightningnetwork/lnd/scripts/verify-install.sh /
COPY --from=builder /go/src/github.com/lightningnetwork/lnd/scripts/keys/* /keys/

RUN sha256sum /bin/lnd /bin/lncli > /shasums.txt \
  && cat /shasums.txt

EXPOSE 9735 10009


ENTRYPOINT ["lnd"]
