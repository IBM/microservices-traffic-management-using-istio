# Deploy Istio service mesh on Kubernetes Cluster

*Read this in other languages: [한국어](GETTING_STARTED-ko.md).*

[Istio](http://istio.io) is an open platform that provides a uniform way to connect, manage, and secure microservices. Istio is the result of a joint collaboration between IBM, Google and Lyft as a means to support traffic flow management, access policy enforcement and the telemetry data aggregation between microservices, all without requiring changes to the code of your microservice. Istio provides an easy way to create this service mesh by deploying a [control plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) and injecting sidecars, an extended version of the  [Envoy](https://lyft.github.io/envoy/) proxy, in the same Pod as your microservice.

# Prerequisite
Create a Kubernetes cluster with either [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) for local testing, or with [IBM Bluemix Container Service](https://github.com/IBM/container-journey-template/blob/master/README.md) to deploy in cloud.

# Steps

## Deploy Istio service mesh on Kubernetes Cluster

## 1. Install Istio on Kubernetes

### 1.1 Download the Istio source

  > Note: This example is tested with istio 0.1.6, we recommend you use this version for consistency.
    Ensure you extract the files to the specified location so that the commands in the instructions
    work for you.

  1. Download Istio release for your OS: [Istio releases](https://github.com/istio/istio/releases)  
  2. Extract the tarball into the `ibm` directory we created earlier.
  3. Copy the `istioctl` bin to somewhere in your executable path

  ```bash
  $ tar xzvf <path-to-istio-download>
  $ mv istio-<VERSION> istio
  $ cp istio/bin/istioctl /usr/local/bin

  ```

### 1.2 Grant Permissions  
  1. Run the following command to check if your cluster has RBAC  
  ```bash
  $ kubectl api-versions | grep rbac
  ```  
  2. Grant permissions based on the version of your RBAC  
    * If you have an **alpha** version, run:

      ```bash
      $ kubectl apply -f istio/install/kubernetes/istio-rbac-alpha.yaml
      ```

    * If you have a **beta** version, run:

      ```bash
      $ kubectl apply -f istio/install/kubernetes/istio-rbac-beta.yaml
      ```

    * If **your cluster has no RBAC** enabled, proceed to installing the **Control Plane**.

### 1.3 Install the [Istio Control Plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) in your cluster  
  1. Run the following command to install Istio.
  ```bash
  $ kubectl apply -f istio/install/kubernetes/istio.yaml
  # or kubectl apply -f istio/install/kubernetes/istio-auth.yaml
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

# Troubleshooting
* To delete Istio from your cluster
```bash
$ kubectl delete -f istio/install/kubernetes/istio-rbac-alpha.yaml # or istio-rbac-beta.yaml
$ kubectl delete -f istio/install/kubernetes/istio.yaml
$ kubectl delete istioconfigs --all
$ kubectl delete thirdpartyresource istio-config.istio.io
```
* To delete all addons: `kubectl delete -f install/kubernetes/addons`

# References
[Istio.io](https://istio.io/docs/tasks/index.html)
# License
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)
