#!/bin/sh

set -x

echo "CMD = $@"

find /run/secrets/
env
#echo $DEPLOYMENT | python -m json.tool

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
    fi
fi

exec /usr/bin/openshift-deploy "$@"
