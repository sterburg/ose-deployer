FROM registry.access.redhat.com/openshift3/ose-deployer:latest

MAINTAINER Steven wolfram

COPY bin/ /usr/local/bin/

ENTRYPOINT /usr/local/bin/entrypoint.sh
