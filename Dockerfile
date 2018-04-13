FROM alpine:3.7

# install common packages
RUN apk add --no-cache curl bash sudo


# COPY rootfs /
COPY rootfs /

# install etcdctl
#RUN chmod +x /usr/local/bin/etcdctl

# install confd
#RUN curl -sSL -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v0.10.0/confd-0.10.0-linux-amd64 \
#   && chmod +x /usr/local/bin/confd

ENV DOCKER_REGISTRY_CONFIG /docker-registry/config/config.yml
ENV SETTINGS_FLAVOR deis



# define the execution environment
WORKDIR /app
CMD ["/app/bin/boot"]
EXPOSE 5000

RUN DOCKER_BUILD=true /app/build.sh

ENV DEIS_RELEASE 1.13.4
