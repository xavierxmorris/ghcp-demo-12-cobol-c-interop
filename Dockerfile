FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        gnucobol3=3.1.2-5.1ubuntu1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["bash", "scripts/build-and-test.sh"]
