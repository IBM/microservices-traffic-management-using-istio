#!/bin/sh

function install_bluemix_cli() {
#statements
echo "Installing Bluemix cli"
curl -L "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" | tar -zx
sudo mv cf /usr/local/bin
sudo curl -o /usr/share/bash-completion/completions/cf https://raw.githubusercontent.com/cloudfoundry/cli/master/ci/installers/completion/cf
cf --version
curl -L public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.1_amd64.tar.gz > Bluemix_CLI.tar.gz
tar -xvf Bluemix_CLI.tar.gz
sudo ./Bluemix_CLI/install_bluemix_cli
}

function bluemix_auth() {
echo "Authenticating with Bluemix"
echo "1" | bx login -a https://api.ng.bluemix.net --apikey $BLUEMIX_AUTH
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
bx plugin install container-service -r Bluemix
echo "Installing kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
}

function cluster_setup() {
bx cs workers $CLUSTER_NAME
$(bx cs cluster-config $CLUSTER_NAME | grep export)

export USERNAME_BASE64=$(echo -n book_user | base64)
export PASSWORD_BASE64=$(echo -n password | base64)
export HOST_BASE64=$(echo -n book-database | base64)
export PORT_BASE64=$(echo -n 3306 | base64)

sed -i s#"YWRtaW4="#$USERNAME_BASE64#g secrets.yaml
sed -i s#"VEhYTktMUFFTWE9BQ1JPRA=="#$PASSWORD_BASE64#g secrets.yaml
sed -i s#"c2wtdXMtc291dGgtMS1wb3J0YWwuMy5kYmxheWVyLmNvbQ=="#$HOST_BASE64#g secrets.yaml
sed -i s#"MTg0ODE="#$PORT_BASE64#g secrets.yaml


curl -L https://git.io/getIstio | sh -
cd $(ls | grep istio)
sudo mv bin/istioctl /usr/local/bin/

kubectl delete --ignore-not-found=true -f install/kubernetes/istio.yaml
kubectl delete --ignore-not-found=true -f install/kubernetes/addons
kubectl delete --ignore-not-found=true -f install/kubernetes/istio-rbac-alpha.yaml
kubectl delete istioconfigs --all
kubectl delete thirdpartyresource istio-config.istio.io
kubectl delete --ignore-not-found=true -f ../bookinfo.yaml
kubectl delete --ignore-not-found=true -f ../book-database.yaml
kubectl delete --ignore-not-found=true -f ../details-new.yaml
kubectl delete --ignore-not-found=true -f ../ratings-new.yaml
kubectl delete --ignore-not-found=true -f ../reviews-new.yaml
kuber=$(kubectl get pods | grep Terminating)
while [ ${#kuber} -ne 0 ]
do
    sleep 5s
    kubectl get pods | grep Terminating
    kuber=$(kubectl get pods | grep Terminating)
done

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
echo "Istio setup done."
}

function initial_setup() {
echo "Creating BookInfo with Injected Envoys..."
echo "Creating local MySQL database..."
kubectl apply -f <(istioctl kube-inject -f ../book-database.yaml)
echo "Creating product page and ingress resource..."
kubectl apply -f <(istioctl kube-inject -f ../bookinfo.yaml)
echo "Creating details service..."
kubectl apply -f <(istioctl kube-inject -f ../details-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
echo "Creating reviews service..."
kubectl apply -f <(istioctl kube-inject -f ../reviews-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
echo "Creating ratings service..."
kubectl apply -f <(istioctl kube-inject -f ../ratings-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)

PODS=$(kubectl get pods | grep Init)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are Initializing..."
    PODS=$(kubectl get pods | grep Init)
    sleep 5s
done

echo "BookInfo done."

}

function health_check() {

export GATEWAY_URL=$(kubectl get po -l istio=ingress -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc istio-ingress -o jsonpath={.spec.ports[0].nodePort})
HEALTH=$(curl -o /dev/null -s -w "%{http_code}\n" http://$GATEWAY_URL/productpage)
if [ $HEALTH -eq 200 ]
then
  echo "Everything looks good."
  echo "Cleaning up..."
  kubectl delete -f install/kubernetes/istio.yaml
  kubectl delete --ignore-not-found=true -f install/kubernetes/addons
  kubectl delete -f install/kubernetes/istio-rbac-alpha.yaml
  kubectl delete istioconfigs --all
  kubectl delete thirdpartyresource istio-config.istio.io
  echo "Deleted Istio in cluster"
  kubectl delete --ignore-not-found=true -f ../book-database.yaml
  kubectl delete --ignore-not-found=true -f ../bookinfo.yaml
  kubectl delete --ignore-not-found=true -f ../details-new.yaml
  kubectl delete --ignore-not-found=true -f ../ratings-new.yaml
  kubectl delete --ignore-not-found=true -f ../reviews-new.yaml
  kuber=$(kubectl get pods | grep Terminating)
  while [ ${#kuber} -ne 0 ]
  do
      sleep 5s
      kubectl get pods | grep Terminating
      kuber=$(kubectl get pods | grep Terminating)
  done
  echo "Deleted Book Info app"
else
  echo "Health check failed."
  exit 1
fi
}



install_bluemix_cli
bluemix_auth
cluster_setup
initial_setup
health_check
