[![Build Status](https://travis-ci.org/IBM/ISTIO-Service-Mesh-on-Kubernetes.svg?branch=master)](https://travis-ci.org/IBM/ISTIO-Service-Mesh-on-Kubernetes)

# Istio BookInfo  
[Istio](http://istio.io) is an open platform that provides a uniform way to connect, manage, and secure microservices. Istio supports managing traffic flows between microservices, enforcing access policies, and aggregating telemetry data, all without requiring changes to the code of your microservice. Istio provides an easy way to create this service mesh by deploying a [control plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) and injecting sidecars, an extended version of the  [Envoy](https://lyft.github.io/envoy/) proxy, in the same Pod as your microservice.

The [BookInfo](https://istio.io/docs/samples/bookinfo.html) is a simple application that is composed of four microservices. The application is written in different languages for each of its microservices namely Python, Java, Ruby, and Node.js.

# Prerequisite

# Deploy to Bluemix
If you want to deploy the BookInfo app directly to Bluemix, click on 'Deploy to Bluemix' button below to create a Bluemix DevOps service toolchain and pipeline for deploying the sample, else jump to [Steps](#steps)

> You will need to create your Kubernetes cluster first and make sure it is fully deployed in your Bluemix account.

[![Create Toolchain](https://github.com/IBM/container-journey-template/blob/master/images/button.png)](https://console.ng.bluemix.net/devops/setup/deploy/)

Please follow the [Toolchain instructions](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions.md) to complete your toolchain and pipeline.

# Steps

1. [Installing Istio](#1-installing-istio-in-your-cluster)
2. [Inject Istio on BookInfo App](#2-inject-istio-envoys-on-bookInfo-application)
3. [Access your Application](#3-access-your-application)
4. [Modify Service Routes](#4-modify-service-routes)

# 1. Installing Istio in your Cluster
## 1.1 Download the Istio source
  1. Download the latest Istio release for your OS: [Istio releases](https://github.com/istio/istio/releases)  
  2. Extract and go to the root directory.
  3. Copy the `istioctl` bin to your local bin  
  ```bash
  $ cp bin/istioctl /usr/local/bin
  ## example for macOS
  ```

## 1.2 Grant Permissions  
  1. Run the following command to check if your cluster has RBAC  
  ```bash
  $ kubectl api-versions | grep rbac
  ```  
  2. Grant permissions based on the version of your RBAC  
    * If you have an **alpha** version, run:

      ```bash
      $ kubectl apply -f install/kubernetes/istio-rbac-alpha.yaml
      ```

    * If you have a **beta** version, run:

      ```bash
      $ kubectl apply -f install/kubernetes/istio-rbac-beta.yaml
      ```

    * If **your cluster has no RBAC** enabled, proceed to installing the **Control Plane**.

## 1.3 Install the [Istio Control Plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) in your cluster  
```bash
kubectl apply -f install/kubernetes/istio.yaml
```
You should now have the Istio Control Plane running in Pods of your Cluster.
```bash
$ kubectl get pods
NAME                              READY     STATUS    RESTARTS
istio-egress-3850639395-30d1v     1/1       Running   0       
istio-ingress-4068702052-2st6r    1/1       Running   0       
istio-manager-251184572-x9dd4     2/2       Running   0       
istio-mixer-2499357295-kn4vq      1/1       Running   0       
```
* _(Optional) For more options/addons such as installing Istio with [Auth feature](https://istio.io/docs/concepts/network-and-auth/auth.html) and [collecting telemetry data](https://istio.io/docs/tasks/metrics-logs.html), go [ here](https://istio.io/docs/tasks/installing-istio.html#prerequisites)._

# 2. Inject Istio Envoys on BookInfo Application
Envoys are deployed as sidecars on each microservice. Injecting Envoy into your microservice means that the Envoy sidecar would manage the ingoing and outgoing calls for the service. To inject an Envoy sidecar to an existing microservice configuration, do:
```bash
$ kubectl apply -f <(istioctl kube-inject -f samples/apps/bookinfo/bookinfo.yaml)
```
After a few minutes, you should now have your Kubernetes Pods running and have an Envoy sidecar in each of them alongside the microservice. The microservices are **productpage, details, ratings, and reviews**. Note that you'll have three versions of the reviews microservice.
```
$ kubectl get pods
NAME                              READY     STATUS    RESTARTS
details-v1-969129648-lwgr3        2/2       Running   0       
istio-egress-3850639395-30d1v     1/1       Running   0       
istio-ingress-4068702052-2st6r    1/1       Running   0       
istio-manager-251184572-x9dd4     2/2       Running   0       
istio-mixer-2499357295-kn4vq      1/1       Running   0       
productpage-v1-1629799384-00f11   2/2       Running   0       
ratings-v1-1194835686-dzf2f       2/2       Running   0       
reviews-v1-2065415949-3gdz5       2/2       Running   0       
reviews-v2-2593570575-92657       2/2       Running   0       
reviews-v3-3121725201-cn371       2/2       Running   0       
```
# 3. Access your Application
To access your application, you can check the public IP address of your cluster through `kubectl get nodes` and get the NodePort of the istio-ingress service for port 80 through `kubectl get svc | grep istio-ingress`. Or you can also run the following command to output the IP address and NodePort:
```bash
echo $(kubectl get po -l istio=ingress -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc istio-ingress -o jsonpath={.spec.ports[0].nodePort})
184.xxx.yyy.zzz:30XYZ
```

Point your browser to:  
`http://184.xxx.yyy.zzz:30XYZ/productpage` Replace with your own IP and NodePort.
# 4. Modify Service Routes
* Set Default Routes to `reviews-v1` for all microservices  
This would set all incoming routes on the services (indicated in the line `destination: <service>`) to the deployment with a tag `version: v1`. To set the default routes, run:
  ```bash
  $ istioctl create -f samples/apps/bookinfo/route-rule-all-v1.yaml
  ```
* Set Route to `reviews-v2` of **reviews microservice** for a specific user  
This would set the route for the user `jason` (You can login as _jason_ with any password in your deploy web application) to see the `version: v2` of the reviews microservice. Run:
  ```bash
  $ istioctl create -f samples/apps/bookinfo/route-rule-reviews-test-v2.yaml
  ```
* Route 50% of traffic on **reviews microservice** to `reviews-v1` and 50% to `reviews-v3`.  
This is indicated by the `weight: 50` in the yaml file.
  ```bash
  $ istioctl replace -f samples/apps/bookinfo/route-rule-reviews-50-v3.yaml
  ```
* Route 100% of the traffic to the `version: v3` of the **reviews microservicese**  
This would set every incoming traffic to the version v3 of the reviews microservice. Run:
  ```bash
  $ istioctl replace -f samples/apps/bookinfo/route-rule-reviews-v3.yaml
  ```
