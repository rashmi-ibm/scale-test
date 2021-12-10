FROM alpine:latest as build
RUN apk add --update alpine-sdk perl openssl-dev && apk add --no-cache git zlib zlib-dev
RUN cd /tmp                               && \
    git clone -b 4.0.2 https://github.com/wg/wrk && \
    cd /tmp/wrk                           && \
    make
RUN cd /tmp && \
    git clone https://github.com/giltene/wrk2.git && \
    cd wrk2 && \
    make

FROM fortio/fortio as fortio

FROM praqma/network-multitool
COPY --from=build /tmp/wrk/wrk /usr/local/bin/
COPY --from=build /tmp/wrk2/wrk /usr/local/bin/wrk2
RUN apk add --no-cache libgcc
ADD run.sh /usr/local/bin/run.sh
COPY --from=fortio /usr/bin/fortio /usr/local/bin/
ENTRYPOINT ["sh"]
