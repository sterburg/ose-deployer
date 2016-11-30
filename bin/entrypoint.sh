#!/bin/sh

set -x

echo "CMD = $@"

mount
find /run/secrets/
env
oc whoami
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get dc
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get rc
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get rc $OPENSHIFT_DEPLOYMENT_NAME
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get rc --template="{{range .spec.template.spec.containers}}{{.name}} {{end}}"
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get pods
oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE export -o json rc/$OPENSHIFT_DEPLOYMENT_NAME

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
        for CNAME in `oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE get rc/$OPENSHIFT_DEPLOYMENT_NAME --template="{{range .spec.template.spec.containers}}{{.name}} {{end}}"`; do
          oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE patch  rc/$OPENSHIFT_DEPLOYMENT_NAME --patch="
            {\"spec\": 
                {\"template\": 
                    {\"spec\": 
                        { \"containers\": 
                            [ { \"name\": \"$CNAME\", 
                                \"env\" : [ { \"name\": \"HTTP_PROXY\" , \"value\": \"$HTTP_PROXY\"  },
                                            { \"name\": \"http_proxy\" , \"value\": \"$http_proxy\"  },
                                            { \"name\": \"HTTPS_PROXY\", \"value\": \"$HTTPS_PROXY\" },
                                            { \"name\": \"https_proxy\", \"value\": \"$https_proxy\" }
                                          ] 
                              } 
                            ] 
                        } 
                    }
                }
            }"
        done
        oc -n $OPENSHIFT_DEPLOYMENT_NAMESPACE export -o json rc/$OPENSHIFT_DEPLOYMENT_NAME
    fi
fi

exec /usr/bin/openshift-deploy "$@"
