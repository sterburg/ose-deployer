```
oc import-image ose-deployer-upstream --from=registry.access.redhat.com/openshift3/ose-deployer:latest --confirm
oc new-build --image-stream=ose-deployer-upstream --code=http://git.openshift.schiphol.nl/Openshift-Infra/ose-deployer.git --strategy=docker
```
