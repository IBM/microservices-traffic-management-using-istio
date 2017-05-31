#!/bin/bash

echo "Creating BookInfo App"

IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep normal | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

curl -L https://git.io/getIstio | sh -
cd $(ls | grep istio)
sudo mv bin/istioctl /usr/local/bin/
echo "default" | ./samples/apps/bookinfo/cleanup.sh

kubectl apply -f install/kubernetes/istio-rbac-alpha.yaml
kubectl apply -f install/kubernetes/istio.yaml

PODS=$(kubectl get pods | grep istio | grep Pending)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are Pending..."
    PODS=$(kubectl get pods | grep istio | grep Pending)
    sleep 5s
done

PODS=$(kubectl get pods | grep istio | grep ContainerCreating)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are still creating Containers..."
    PODS=$(kubectl get pods | grep istio | grep ContainerCreating)
    sleep 5s
done

echo "Finished Istio Control Plane setup."
sleep 5s

echo "Creating BookInfo with Injected Envoys..."
kubectl apply -f <(istioctl kube-inject -f samples/apps/bookinfo/bookinfo.yaml)

PODS=$(kubectl get pods | grep Init)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are Initializing..."
    PODS=$(kubectl get pods | grep Init)
    sleep 5s
done

echo "BookInfo done."

echo "Getting IP and Port"
kubectl get nodes
kubectl get svc | grep ingress
export GATEWAY_URL=$(kubectl get po -l istio=ingress -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -o 'jsonpath={.spec.ports[0].nodePort}')
echo $GATEWAY_URL
if [ -z "$GATEWAY_URL" ]
then
    echo "GATEWAY_URL not found"
    exit 1
fi
kubectl get pods,svc
echo "You can now view your Sample BookInfo App http://$GATEWAY_URL"
echo "To modify service routes. You will need to do it in your own environment"
echo "Execute \"bx cs cluster-config $CLUSTER_NAME\" on your environment then export the resulting variable KUBECONFIG."
echo "You can now do \"istioctl create -f <route-yaml-config>\""
echo "Sample route configurations are located in sample/apps/bookinfo/ in your istio installation directory."
