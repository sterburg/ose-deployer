## Introduction
This adds to the existing OpenShift Deployer the possibility to ad-hoc inject HTTP_PROXY environment variables.
Can also be used to "just-in-time" inject anything else or do a different deployment logic.

## Create custom ose-deployer
```
oc new-project openshift3
oc import-image ose-deployer-upstream --from=registry.access.redhat.com/openshift3/ose-deployer:latest --confirm
oc new-build --image-stream=ose-deployer-upstream --code=https://github.com/sterburg/ose-deployer.git --strategy=docker
```

## Preparing nodes to pull the new ose-deployer
```
oc describe sa default -n openshift3                       #find the mountable dockercfg secret
oc describe secret default-dockercfg-c8tif -n openshift3   #copy the image pull .dockercfg content

## Prepare nodes for a docker pull from local registry ##
ssh deploy@ansiblehost
ansible  -m shell -a "command perl -pi -e 's/latest: false/latest: true/' /etc/origin/master/master-config.yaml" masters
ansible  -m shell -a "command perl -pi -e 's/latest: false/latest: true/' /etc/origin/node/node-config.yaml" nodes
ansible  -m shell -a "command systemctl restart atomic-openshift-master-api" masters
ansible  -m shell -a "command systemctl restart atomic-openshift-master-controllers" masters
ansible  -m shell -a "command systemctl restart atomic-openshift-node" node

ansible  -m shell -a "command mkdir /etc/docker/certs.d/docker-registry-default.openshift.company.nl/" nodes
ansible  -m copy -a "src=/home/deploy/certs/openshift-ca.crt dest=/etc/docker/certs.d/docker-registry-default.openshift.company.nl/ca.crt" nodes
ansible  -m shell -a "command perl -pi -e 's/registry.access.redhat.com/docker-registry-default.openshift.company.nl --add-registry registry.access.redhat.com/' /etc/sysconfig/docker" nodes
ansible  -m shell -a "command docker login -u serviceaccount -e serviceaccount@example.com -p 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9’ docker-registry-default.openshift.company.nl” nodes
ansible  -m shell -a "command systemctl restart docker" nodes
ansible  -m shell -a "docker pull docker-registry-default.openshift.company.nl/openshift3/ose-deployer:latest" nodes
ansible  -m shell -a "docker tag  docker-registry-default.openshift.company.nl/openshift3/ose-deployer:latest openshift3/ose-deployer:latest" nodes
```
