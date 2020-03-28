FROM alpine:3.11

ENV HUGO_VERSION=0.68.3

RUN apk add --no-cache -U \
  bash \
  curl

RUN mkdir -p /tmp/hugo \
  && curl -fsSL -o /tmp/hugo/hugo.tar.gz https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
  && cd /tmp/hugo \
  && tar zxvf hugo.tar.gz \
  && mv hugo /hugo \
  && cd ../ \
  && rm -rf hugo

ENTRYPOINT ["/hugo"]
