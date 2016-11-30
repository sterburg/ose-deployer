#!/bin/sh

set -x

echo "CMD = $@"

mount
find /run/secrets/
env
oc whoami
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get dc
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get rc
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get pods
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE export -o json rc/$OPENSHIFT_DEPLOYMENT_NAME
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE export -o json rc/$OPENSHIFT_DEPLOYMENT_NAME | python -m json.tool

if [ "$HTTP_PROXY" == "" ]; then
    export OPS_NAMESPACE=`grep search /etc/resolv.conf |awk '{sub(".svc","-ops.svc", $2); print $2 }'`
    export PROXY_HOST="proxy.$OPS_NAMESPACE"
    export PROXY_PORT=8080
    
    ## Only set proxy if proxy actually exists
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/$PROXY_HOST/$PROXY_PORT"
    if [ "$?" == "0" ]; then
        export HTTP_PROXY="http://$PROXY_HOST:$PROXY_PORT"
        export HTTPS_PROXY="$HTTP_PROXY"
        export http_proxy="$HTTP_PROXY"
        export https_proxy="$HTTP_PROXY"
        #export NO_PROXY
        oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE patch  rc/$OPENSHIFT_DEPLOYMENT_NAME --patch="{'spec': {'template': {'spec': { 'containers': [ { 'env': [ { 'name': 'HTTP_PROXY', 'value': '$HTTP_PROXY' } ] } ] } } } }" && true
    fi
fi

exec /usr/bin/openshift-deploy "$@"
