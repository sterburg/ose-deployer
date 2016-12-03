FROM registry.access.redhat.com/openshift3/ose-deployer:latest

MAINTAINER Samuel Terburg <sterburg@redhat.com>

COPY bin/ /usr/local/bin/

ENTRYPOINT /usr/local/bin/entrypoint.sh
