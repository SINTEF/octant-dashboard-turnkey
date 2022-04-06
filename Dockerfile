FROM alpine:3 AS builder

ARG OCTANT_VERSION=0.25.1
# Can be 64bit (for amd64), arm, and arm64
ARG OCTANT_ARCH=64bit
ARG OCTANT_CHECKSUM=b12bb6752e43f4e0fe54278df8e98dee3439c4066f66cdb7a0ca4a1c7d8eaa1e

ADD https://github.com/vmware-tanzu/octant/releases/download/v${OCTANT_VERSION}/octant_${OCTANT_VERSION}_Linux-${OCTANT_ARCH}.tar.gz /tmp/octant.tar.gz

RUN sha256sum /tmp/octant.tar.gz | grep "$OCTANT_CHECKSUM" && \
    if [[ $? -ne 0 ]]; then echo "Bad checksum"; exit 444; fi && \
    tar -xzvf /tmp/octant.tar.gz --strip 1 -C /opt

FROM alpine:3
RUN addgroup -g 2000 -S octant && adduser -u 1000 -h /home/octant -G octant -S octant
COPY --from=builder /opt/octant /opt/octant
COPY docker-entrypoint.sh /
ENTRYPOINT /docker-entrypoint.sh