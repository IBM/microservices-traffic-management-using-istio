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
export PATH="$PATH:$(pwd)/bin"

echo "Deleting existing Istio control plane and book info application"
kubectl delete --ignore-not-found=true -f install/kubernetes/istio.yaml
kubectl delete --ignore-not-found=true -f install/kubernetes/addons
kubectl delete --ignore-not-found=true -f install/kubernetes/istio-rbac-alpha.yaml
kubectl delete istioconfigs --all
kubectl delete thirdpartyresource istio-config.istio.io
kubectl delete --ignore-not-found=true -f ../book-database.yaml
kubectl delete --ignore-not-found=true -f ../bookinfo.yaml
kubectl delete --ignore-not-found=true -f ../details-new.yaml
kubectl delete --ignore-not-found=true -f ../ratings-new.yaml
kubectl delete --ignore-not-found=true -f ../reviews-new.yaml
kubectl delete --ignore-not-found=true -f secrets.yaml

kuber=$(kubectl get pods | grep Terminating)
while [ ${#kuber} -ne 0 ]
do
    sleep 5s
    kubectl get pods | grep Terminating
    kuber=$(kubectl get pods | grep Terminating)
done

echo "CREATING ISTIO CONTROL PLANE"
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

if [[ -z $MYSQL_DB_USER ]] && [[ -z $MYSQL_DB_PASSWORD ]] && [[ -z $MYSQL_DB_HOST ]] && [[ -z $MYSQL_DB_PORT ]]
then
  echo "MYSQL_DB_USER,PASSWORD,HOST,PORT are not set. Going to be using MySQL in a container inside the cluster."
  cd ..
  export USERNAME_BASE64=$(echo -n book_user | base64)
  export PASSWORD_BASE64=$(echo -n password | base64)
  export HOST_BASE64=$(echo -n book-database | base64)
  export PORT_BASE64=$(echo -n 3306 | base64)

  sed -i s#"YWRtaW4="#$USERNAME_BASE64#g secrets.yaml
  sed -i s#"VEhYTktMUFFTWE9BQ1JPRA=="#$PASSWORD_BASE64#g secrets.yaml
  sed -i s#"c2wtdXMtc291dGgtMS1wb3J0YWwuMy5kYmxheWVyLmNvbQ=="#$HOST_BASE64#g secrets.yaml
  sed -i s#"MTg0ODE="#$PORT_BASE64#g secrets.yaml
  cat secrets.yaml
  kubectl apply -f secrets.yaml
  kubectl apply -f <(istioctl kube-inject -f book-database.yaml)
else
  echo "Changing variables..."
  cd ..
  export MYSQL_DB_USER=$(echo -n $MYSQL_DB_USER | base64)
  export MYSQL_DB_PASSWORD=$(echo -n $MYSQL_DB_PASSWORD | base64)
  export MYSQL_DB_HOST=$(echo -n $MYSQL_DB_HOST | base64)
  export MYSQL_DB_PORT=$(echo -n $MYSQL_DB_PORT | base64)

  sed -i s#"YWRtaW4="#$MYSQL_DB_USER#g secrets.yaml
  sed -i s#"VEhYTktMUFFTWE9BQ1JPRA=="#$MYSQL_DB_PASSWORD#g secrets.yaml
  sed -i s#"c2wtdXMtc291dGgtMS1wb3J0YWwuMy5kYmxheWVyLmNvbQ=="#$MYSQL_DB_HOST#g secrets.yaml
  sed -i s#"MTg0ODE="#$MYSQL_DB_PORT#g secrets.yaml
  cat secrets.yaml
  kubectl apply -f secrets.yaml
  kubectl apply -f mysql-data.yaml
fi

echo "Creating BookInfo with Injected Envoys..."
echo "Creating product page and ingress resource..."
kubectl apply -f <(istioctl kube-inject -f bookinfo.yaml)
echo "Creating details service..."
kubectl apply -f <(istioctl kube-inject -f details-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
echo "Creating reviews service..."
kubectl apply -f <(istioctl kube-inject -f reviews-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
echo "Creating ratings service..."
kubectl apply -f <(istioctl kube-inject -f ratings-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)

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
echo "You can now view your Sample BookInfo App http://$GATEWAY_URL/productpage"
echo "To modify service routes. You will need to do it in your own environment"
echo "Execute \"bx cs cluster-config $CLUSTER_NAME\" on your environment then export the resulting variable KUBECONFIG."
echo "You can now do \"istioctl create -f <route-yaml-config>\""
echo "Sample route configurations are located in sample/apps/bookinfo/ in your istio installation directory."
