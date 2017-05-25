# Istio BookInfo

[Istio](http://istio.io) is an open platform that provides a uniform way to connect, manage, and secure microservices. Istio supports managing traffic flows between microservices, enforcing access policies, and aggregating telemetry data, all without requiring changes to the code of your microservice. Istio provides an easy way to create this service mesh by deploying a [control plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) and injecting sidecars called [Envoy](https://istio.io/docs/concepts/what-is-istio/overview.html#envoy) in the same Pod as your microservice.

The [BookInfo](https://istio.io/docs/samples/bookinfo.html) is a simple application that is composed of four microservices. The application is written in different languages for each of its microservices namely Python, Java, Ruby, and Node.js.

# Prerequisite

# Deploy to Bluemix

# 1. Installing Istio in your Cluster
* Download the source code  
  1. Download the latest Istio release for your OS: [Istio releases](https://github.com/istio/istio/releases)  
  2. Extract and go to the root directory.
  3. Copy the `istioctl` bin to your local bin  
  ```
  $ cp bin/istioctl /usr/local/bin
  ## example for macOS
  ```
* Grant Permissions  
  1. Run the following command to check if your cluster has RBAC  
  ```
  $ kubectl api-versions | grep rbac
  ```
  2. Grant permissions  
  ```
  If you have an alpha version, run:
  $ kubectl apply -f install/kubernetes/istio-rbac-alpha.yaml
  If you have a beta version, run:
  $ kubectl apply -f install/kubernetes/istio-rbac-beta.yaml
  If none, proceed to installing the Control Plane
  ```
* Install the Istio Control Plane in your cluster  
```bash
kubectl apply -f install/kubernetes/istio.yaml
```
* _(Optional) For more options/addons such as installing Istio with [Auth](https://istio.io/docs/concepts/network-and-auth/auth.html) feature and [collecting telemetry data](https://istio.io/docs/tasks/metrics-logs.html), go [ here](https://istio.io/docs/tasks/installing-istio.html#prerequisites)._

# 2. Inject Istio Envoys on BookInfo Application
```bash
$ kubectl apply -f <(istioctl kube-inject -f samples/apps/bookinfo/bookinfo.yaml)
```
# 3. Access your Application
```bash
echo $(kubectl get po -l istio=ingress -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc istio-ingress -o jsonpath={.spec.ports[0].nodePort})
184.xxx.yyy.zzz:30XYZ
```
`http://184.xxx.yyy.zzz:30XYZ/productpage`
# 4. Modify Service Routes
