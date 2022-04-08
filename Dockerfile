ARG BEANCOUNT_VERSION=2.3.5
ARG NODE_BUILD_IMAGE=16-bullseye
ARG ARCH=x86_64
ARG SOURCE_BRANCH

FROM node:${NODE_BUILD_IMAGE} as node_build_env
ARG SOURCE_BRANCH
ENV FAVA_VERSION=${SOURCE_BRANCH:-v1.21}

RUN apt-get update && apt-get install -y python3-babel python3-pip && python3 -m pip install -U Babel

WORKDIR /tmp/build
RUN git clone https://github.com/beancount/fava

WORKDIR /tmp/build/fava
RUN git checkout ${FAVA_VERSION} && make && make mostlyclean

FROM debian:bullseye as build_env
ARG BEANCOUNT_VERSION
ARG ARCH

RUN apt-get update
RUN apt-get install -y build-essential libxml2-dev libxslt-dev curl git \
        python3 \
        libpython3-dev \
        python3-pip \
        python3-venv


ENV PATH "/app/bin:$PATH"
RUN python3 -mvenv /app
RUN pip3 install -U pip setuptools argh
# argh required for fava_investor installed after fava.

COPY --from=node_build_env /tmp/build/fava /tmp/build/fava

WORKDIR /tmp/build
RUN git clone https://github.com/beancount/beancount

WORKDIR /tmp/build/beancount
RUN git checkout ${BEANCOUNT_VERSION}

RUN CFLAGS=-s pip3 install -U /tmp/build/beancount

# these things require beancount.
RUN pip install beancount-import \
    && pip install beancount_portfolio_allocation \
    && pip install git+https://github.com/beancount/beanprice.git 

RUN pip3 install -U /tmp/build/fava

RUN \
  pip install -f -U git+https://github.com/polarmutex/fava-envelope.git@master \
  && pip install -f -U git+https://github.com/redstreet/fava_investor.git@master

RUN pip3 uninstall -y pip

RUN find /app -name __pycache__ -exec rm -rf -v {} +

WORKDIR /s6/
# s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.0.1/s6-overlay-${ARCH}.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.0.1/s6-overlay-noarch.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.0.1/s6-overlay-symlinks-arch.tar.xz /tmp/

RUN  xz -dc /tmp/s6-overlay-${ARCH}.tar.xz | tar x \
  && xz -dc /tmp/s6-overlay-noarch.tar.xz | tar x \
  && xz -dc /tmp/s6-overlay-symlinks-arch.tar.xz | tar x

FROM gcr.io/distroless/python3-debian11
COPY --from=build_env /app /app

COPY --from=build_env /s6 /

# Default fava port number
EXPOSE 5000
EXPOSE 8101

ENV BEANCOUNT_FILE ""

# Required by Click library.
# See https://click.palletsprojects.com/en/7.x/python3/
ENV LC_ALL "C.UTF-8"
ENV LANG "C.UTF-8"
ENV FAVA_HOST "0.0.0.0"
ENV PATH "/app/bin:$PATH"

ENTRYPOINT ["/init"]
