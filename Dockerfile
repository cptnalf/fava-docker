ARG BEANCOUNT_VERSION=2.3.5
ARG NODE_BUILD_IMAGE=16-bullseye
ARG ARCH=x86_64
ARG SOURCE_BRANCH
ARG FAVA_VERSION=${SOURCE_BRANCH:-1.22.1}

FROM debian:bullseye as build_env
ARG BEANCOUNT_VERSION
ARG ARCH
ARG FAVA_VERSION

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

RUN python3 -m pip install beancount==${BEANCOUNT_VERSION} \
  && python3 -m pip install fava==${FAVA_VERSION}

# these things require beancount.
RUN python3 -m pip install beancount-import \
    && python3 -m pip install beancount_portfolio_allocation \
    && python3 -m pip install https://github.com/beancount/beanprice/archive/master.tar.gz

RUN \
  python3 -m pip install fava-envelope==0.5.4 fava_investor==0.2.7

RUN pip3 cache purge
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
COPY rootfs/ /

# Default fava port number
EXPOSE 5000
EXPOSE 8101

ENV BEANCOUNT_FILE ""
ENV UID 0
ENV GID 0
ENV GIDLIST 0 
# Required by Click library.
# See https://click.palletsprojects.com/en/7.x/python3/
ENV LC_ALL "C.UTF-8"
ENV LANG "C.UTF-8"
ENV FAVA_HOST "0.0.0.0"
ENV PATH "/app/bin:/command:/usr/bin:/bin:$PATH"

ENTRYPOINT ["/init"]
CMD ["/runfava" ]
