# Getting started: Deploy Istio service mesh and sample application on Kubernetes Cluster

[Istio](http://istio.io) is an open platform that provides a uniform way to connect, manage, and secure microservices. Istio is the result of a joint collaboration between IBM, Google and Lyft as a means to support traffic flow management, access policy enforcement and the telemetry data aggregation between microservices, all without requiring changes to the code of your microservice. Istio provides an easy way to create this service mesh by deploying a [control plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) and injecting sidecars, an extended version of the  [Envoy](https://lyft.github.io/envoy/) proxy, in the same Pod as your microservice.

The [BookInfo](https://istio.io/docs/samples/bookinfo.html) is a simple application that is composed of four microservices. The application is written in different languages for each of its microservices namely Python, Java, Ruby, and Node.js.

# Prerequisite
Create a Kubernetes cluster with either [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) for local testing, or with [IBM Bluemix Container Service](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions_new.md) to deploy in cloud. The code here is regularly tested against [Kubernetes Cluster from Bluemix Container Service](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov) using Travis.

# Steps

## Deploy Istio service mesh and application on Kubernetes Cluster

![ISTIO-PART-A](images/ISTIO-PART-A.png)

1. [Install Istio on Kubernetes](#1-install-istio-on-kubernetes)
2. [Deploy sample BookInfo application on Kubernetes](#2-deploy-sample-bookinfo-application-on-kubernetes)
3. [Inject Istio envoys on the application](#3-inject-istio-envoys-on-the-application)
4. [Access your application running on Istio](#4-access-your-application-running-on-istio)

## 1. Install Istio on Kubernetes

### 1.1 Download the Istio source
  1. Download the latest Istio release for your OS: [Istio releases](https://github.com/istio/istio/releases)  
  2. Extract and go to the root directory.
  3. Copy the `istioctl` bin to your local bin  
  ```bash
  $ cp bin/istioctl /usr/local/bin
  ## example for macOS
  ```

### 1.2 Grant Permissions  
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

### 1.3 Install the [Istio Control Plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) in your cluster  
  1. Run the following command to install Istio.
  ```bash
  $ kubectl apply -f install/kubernetes/istio.yaml
  # or kubectl apply -f install/kubernetes/istio-auth.yaml
  ```
  > `istio-auth.yaml` enables Istio with its [Auth](https://istio.io/docs/concepts/network-and-auth/auth.html) feature. It enables [mTLS](https://en.wikipedia.org/wiki/Mutual_authentication) between the services

  2. You should now have the Istio Control Plane running in Pods of your Cluster.
  ```bash
  $ kubectl get pods
  NAME                              READY     STATUS    RESTARTS
  istio-egress-3850639395-30d1v     1/1       Running   0       
  istio-ingress-4068702052-2st6r    1/1       Running   0       
  istio-pilot-251184572-x9dd4       2/2       Running   0       
  istio-mixer-2499357295-kn4vq      1/1       Running   0       
  ```
## 2. Deploy sample BookInfo application on Kubernetes

In this step, it assumes that you already have your own application that is configured to run in a Kubernetes Cluster.  
In this journey, you will be using the BookInfo Application that can already run on a Kubernetes Cluster. You can deploy the BookInfo Application without using Istio by not injecting the required Envoys.
* Deploy the BookInfo Application in your Cluster
```bash
$ kubectl apply -f samples/apps/bookinfo/bookinfo.yaml
```
* If you don't have access to external load balancers, you need to use NodePort on the `productpage` service. Run the following command to use a NodePort:
```yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: productpage
  labels:
    app: productpage
spec:
  type: NodePort
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
EOF
```
* Output your cluster's IP address and NodePort of your `productpage` service in your terminal: _(If you have a load balancer, you can access it through the IP found on `kubectl get ingress`)_
```bash
$ echo $(kubectl get po -l app=productpage -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc productpage -o jsonpath={.spec.ports[0].nodePort})
184.xxx.yyy.zzz:30XYZ
```
At this point, you can point your browser to http://184.xxx.yyy.zzz:30XYZ/productpage and see the BookInfo Application. The sample BookInfo Application is configured to run on a Kubernetes Cluster.  
The next step would be deploying this sample application with Istio Envoys injected. By using Istio, you will have access to Istio's features such as _traffic flow management, access policy enforcement and telemetry data aggregation between microservices_. You will not have to modify the BookInfo's source code.

You should now delete the sample application to proceed to the next step.
```bash
$ kubectl delete -f samples/apps/bookinfo/bookinfo.yaml
```

## 3. Inject Istio envoys on the application

Envoys are deployed as sidecars on each microservice. Injecting Envoy into your microservice means that the Envoy sidecar would manage the ingoing and outgoing calls for the service. To inject an Envoy sidecar to an existing microservice configuration, do:
```bash
$ kubectl apply -f <(istioctl kube-inject -f samples/apps/bookinfo/bookinfo.yaml)
```
> `istioctl kube-inject` modifies the yaml file passed in _-f_. This injects Envoy sidecar into your Kubernetes resource configuration. The only resources updated are Job, DaemonSet, ReplicaSet, and Deployment. Other resources in the YAML file configuration will be left unmodified.

After a few minutes, you should now have your Kubernetes Pods running and have an Envoy sidecar in each of them alongside the microservice. The microservices are **productpage, details, ratings, and reviews**. Note that you'll have three versions of the reviews microservice.
```
$ kubectl get pods

NAME                              READY     STATUS    RESTARTS
details-v1-969129648-lwgr3        2/2       Running   0       
istio-egress-3850639395-30d1v     1/1       Running   0       
istio-ingress-4068702052-2st6r    1/1       Running   0       
istio-pilot-251184572-x9dd4     2/2       Running   0       
istio-mixer-2499357295-kn4vq      1/1       Running   0       
productpage-v1-1629799384-00f11   2/2       Running   0       
ratings-v1-1194835686-dzf2f       2/2       Running   0       
reviews-v1-2065415949-3gdz5       2/2       Running   0       
reviews-v2-2593570575-92657       2/2       Running   0       
reviews-v3-3121725201-cn371       2/2       Running   0       
```
## 4. Access your application running on Istio

To access your application, you can check the public IP address of your cluster through `kubectl get nodes` and get the NodePort of the istio-ingress service for port 80 through `kubectl get svc | grep istio-ingress`. Or you can also run the following command to output the IP address and NodePort:
```bash
echo $(kubectl get po -l istio=ingress -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc istio-ingress -o jsonpath={.spec.ports[0].nodePort})
184.xxx.yyy.zzz:30XYZ
```

Point your browser to:  
`http://184.xxx.yyy.zzz:30XYZ/productpage` Replace with your own IP and NodePort.

If you refresh the page multiple times, you'll see that the _reviews_ section of the page changes. That's because there are 3 versions of **reviews**_(reviews-v1, reviews-v2, reviews-v3)_ deployment for our **reviews** service.
![productpage](images/none.png)
![productpage](images/black.png)
![productpage](images/red.png)

Now that you have tried the sample Book Info application, you will need to delete it before proceeding to deploy a [modified Book Info application](/README.md).
```bash
$ kubectl delete -f samples/apps/bookinfo/bookinfo.yaml
```

# Troubleshooting
* To delete Istio from your cluster
```bash
$ kubectl delete -f install/kubernetes/istio-rbac-alpha.yaml # or istio-rbac-beta.yaml
$ kubectl delete -f install/kubernetes/istio.yaml
$ kubectl delete istioconfigs --all
$ kubectl delete thirdpartyresource istio-config.istio.io
```
* To delete all addons: `kubectl delete -f install/kubernetes/addons`
* To delete the BookInfo app and its route-rules: `./samples/apps/bookinfo/cleanup.sh`

# References
[Istio.io](https://istio.io/docs/tasks/index.html)
# License
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)
