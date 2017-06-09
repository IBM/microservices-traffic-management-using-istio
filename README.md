[![Build Status](https://travis-ci.org/IBM/Microservices-with-Istio-Service-Mesh-on-Kubernetes.svg?branch=master)](https://travis-ci.org/IBM/Microservices-with-Istio-Service-Mesh-on-Kubernetes)

# Deploy microservices with load balancing, access policies, telemetry and reporting leveraging Istio Service Mesh on Kubernetes

[Istio](http://istio.io) is an open platform that provides a uniform way to connect, manage, and secure microservices. Istio is the result of a joint collaboration between IBM, Google and Lyft as a means to support traffic flow management, access policy enforcement and the telemetry data aggregation between microservices, all without requiring changes to the code of your microservice. Istio provides an easy way to create this service mesh by deploying a [control plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) and injecting sidecars, an extended version of the  [Envoy](https://lyft.github.io/envoy/) proxy, in the same Pod as your microservice.

The [BookInfo](https://istio.io/docs/samples/bookinfo.html) is a simple application that is composed of four microservices. The application is written in different languages for each of its microservices namely Python, Java, Ruby, and Node.js.

## Included Components
- [Istio](https://istio.io/)
- [Kubernetes Clusters](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov)
- [Grafana](http://docs.grafana.org/guides/getting_started)
- [Zipkin](http://zipkin.io/)
- [Prometheus](https://prometheus.io/)
- [Bluemix container service](https://console.ng.bluemix.net/catalog/?taxonomyNavigation=apps&category=containers)
- [Bluemix DevOps Toolchain Service](https://console.ng.bluemix.net/catalog/services/continuous-delivery)

## Scenarios
[Part A: Deploy Istio service mesh and sample application on Kubernetes](#part-a-deploy-istio-service-mesh-and-sample-application-on-kubernetes-1)

![ISTIO-PART-A](images/ISTIO-PART-A.png)

[Part B: Configure and use Istio's features for sample application](#part-b-configure-and-use-istios-features-for-sample-application-1)

![ISTIO-PART-B](images/ISTIO-PART-B.png)

# Prerequisite
Create a Kubernetes cluster with either [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) for local testing, or with [IBM Bluemix Container Service](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions_new.md) to deploy in cloud. The code here is regularly tested against [Kubernetes Cluster from Bluemix Container Service](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov) using Travis.

# Deploy to Bluemix
If you want to deploy the BookInfo app directly to Bluemix, click on 'Deploy to Bluemix' button below to create a Bluemix DevOps service toolchain and pipeline for deploying the sample, else jump to [Steps](#steps)

> You will need to create your Kubernetes cluster first and make sure it is fully deployed in your Bluemix account.

[![Create Toolchain](https://github.com/IBM/container-journey-template/blob/master/images/button.png)](https://console.ng.bluemix.net/devops/setup/deploy/)

Please follow the [Toolchain instructions](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions.md) to complete your toolchain and pipeline.

# Steps

## Part A: Deploy Istio service mesh and sample application on Kubernetes

1. [Install Istio on Kubernetes](#1-install-istio-on-kubernetes)
2. [Deploy sample BookInfo application on Kubernetes](#2-deploy-sample-bookinfo-application-on-kubernetes)
3. [Inject Istio envoys on the application](#3-inject-istio-envoys-on-the-application)
4. [Access your application running on Istio](#4-access-your-application-running-on-istio)

## Part B: Configure and use Istio's features for sample application

5. [Traffic flow management - Modify service routes](#5-traffic-flow-management---modify-service-routes)
6. [Access policy enforcement - Configure access control](#6-access-policy-enforcement---configure-access-control)
7. [Telemetry data aggregation - Collect metrics, logs and trace spans](#7-telemetry-data-aggregation---collect-metrics-logs-and-trace-spans)
     - 7.1 [Collect metrics and logs using Prometheus and Grafana](#71-collect-metrics-and-logs-using-prometheus-and-grafana)
     - 7.2 [Collect request traces using Zipkin](#72-collect-request-traces-using-zipkin)

## Part C: Enable Egress Traffic for sample application

8. [Create a MySQL Database](#8-create-a-mysql-database)
9. [Configure your sample application](#9-configure-your-sample-application)
10. [Inject Istio envoys with Egress traffic enabled on the application](#10-inject-istio-envoys-with-egress-traffic-enabled-on-the-application)

#### [Troubleshooting](#troubleshooting-1)

# Part A: Deploy Istio service mesh and sample application on Kubernetes

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
  istio-manager-251184572-x9dd4     2/2       Running   0       
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
istio-manager-251184572-x9dd4     2/2       Running   0       
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

# Part B: Configure and use Istio's features for sample application

## 5. Traffic flow management - Modify service routes

This step shows you how to configure where you want your service to go based on weights and HTTP Headers.
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
  # using `replace` should allow you to edit exisiting route-rules.
  ```
* Route 100% of the traffic to the `version: v3` of the **reviews microservicese**  
This would set every incoming traffic to the version v3 of the reviews microservice. Run:
  ```bash
  $ istioctl replace -f samples/apps/bookinfo/route-rule-reviews-v3.yaml
  ```

## 6. Access policy enforcement - Configure access control

This step shows you how to control access to your services. If you have done the step above, you'll see that your `productpage` now just shows red stars on the reviews section and if you are logged in as _jason_, you'll see black stars. The `ratings` service is accessed from the `reviews-v2` if you're logged in as _jason_ or it is accessed from `reviews-v3` if you are not logged in as `jason`.

* To deny access to the ratings service from the traffic coming from `reviews-v3`, you will use `istioctl mixer rule create`
  ```bash
  $ istioctl mixer rule create global ratings.default.svc.cluster.local -f samples/apps/bookinfo/mixer-rule-ratings-denial.yaml
  ```
  The `mixer-rule-ratings-denial.yaml` file creates a rule that denies `kind: denials` access from reviews service and has a label of v3 `selector: source.labels["app"]=="reviews" && source.labels["version"] == "v3"`  
  You can verify using `istioctl mixer rule get global ratings.default.svc.cluster.local` if the mixer rule has been created that way:
  ```yaml
  $ istioctl mixer rule get global ratings.default.svc.cluster.local
  rules:
  - aspects:
    - kind: denials
    selector: source.labels["app"]=="reviews" && source.labels["version"] == "v3"
  ```
* To verify if your rule has been enforced, point your browser to your BookInfo Application, you wouldn't see star ratings anymore from the reviews section unless you are logged in as _jason_ which you will still see black stars (because you would be using the reviews-v2 as you have done in [Step 4](#4-modify-service-routes)).
![access-control](images/access.png)


## 7. Telemetry data aggregation - Collect metrics, logs and trace spans

### 7.1 Collect metrics and logs using Prometheus and Grafana

This step shows you how to configure [Istio Mixer](https://istio.io/docs/concepts/policy-and-control/mixer.html) to gather telemetry for services in your cluster.

* Install the required Istio Addons on your cluster: [Prometheus](https://prometheus.io) and [Grafana](https://grafana.com)
  ```bash
  $ kubectl apply -f install/kubernetes/addons/prometheus.yaml
  $ kubectl apply -f install/kubernetes/addons/grafana.yaml
  ```
* Verify that your **Grafana** dashboard is ready. Get the IP of your cluster `kubectl get nodes` and then the NodePort of your Grafana service `kubectl get svc | grep grafana` or you can run the following command to output both:
  ```bash
  $ echo $(kubectl get po -l app=grafana -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc grafana -o jsonpath={.spec.ports[0].nodePort})
  184.xxx.yyy.zzz:30XYZ
  ```
  Point your browser to `184.xxx.yyy.zzz:30XYZ/dashboard/db/istio-dashboard` to go directly to your dashboard.  
  Your dashboard should look like this:  
  ![Grafana-Dashboard](images/grafana.png)

* To collect new telemetry data, you will use `istio mixer rule create`. For this sample, you will generate logs for Response Size for Reviews service. The configuration YAML file is provided within the BookInfo sample folder. Validate that your Reviews service has no service-specific rules already applied.
  ```bash
  $ istioctl mixer rule get reviews.default.svc.cluster.local reviews.default.svc.cluster.local
  Error: the server could not find the requested resource
  ```
* Create a configuration YAML file and name it as `new_rule.yaml`:
  ```yaml
  revision: "1"
  rules:
  - aspects:
    - adapter: prometheus
      kind: metrics
      params:
        metrics:
        - descriptor_name: response_size
          value: response.size | 0
          labels:
            source: source.labels["app"] | "unknown"
            target: target.service | "unknown"
            service: target.labels["app"] | "unknown"
            version: target.labels["version"] | "unknown"
            method: request.path | "unknown"
            response_code: response.code | 200
    - adapter: default
      kind: access-logs
      params:
        logName: combined_log
        log:
          descriptor_name: accesslog.combined
          template_expressions:
            originIp: origin.ip
            sourceUser: origin.user
            timestamp: request.time
            method: request.method
            url: request.path
            protocol: request.scheme
            responseCode: response.code
            responseSize: response.size
            referer: request.referer
            userAgent: request.headers["user-agent"]
          labels:
            originIp: origin.ip
            sourceUser: origin.user
            timestamp: request.time
            method: request.method
            url: request.path
            protocol: request.scheme
            responseCode: response.code
            responseSize: response.size
            referer: request.referer
            userAgent: request.headers["user-agent"]
  ```
* Create the configuration on Istio Mixer.
  ```bash
  istioctl mixer rule create reviews.default.svc.cluster.local reviews.default.svc.cluster.local -f new_rule.yaml
  ```
* Send traffic to that service by refreshing your browser to `http://184.xxx.yyy.zzz:30XYZ/productpage` multiple times. You can also do `curl` on your terminal to that URL in a while loop.

* Verify that the new metric is being collected by going to your Grafana dashboard again. The graph on the rightmost should now be populated.
![grafana-new-metric](images/grafana-new-metric.png)

* Verify that the logs stream has been created and is being populated for requests
  ```bash
  $ kubectl logs $(kubectl get pods -l istio=mixer -o jsonpath='{.items[0].metadata.name}') | grep \"combined_log\"
  {"logName":"combined_log","labels":{"referer":"","responseSize":871,"timestamp":"2017-04-29T02:11:54.989466058Z","url":"/reviews","userAgent":"python-requests/2.11.1"},"textPayload":"- - - [29/Apr/2017:02:11:54 +0000] \"- /reviews -\" - 871 - python-requests/2.11.1"}
  ...
  ...
  ...
  ```

[Collecting Metrics and Logs on Istio](https://istio.io/docs/tasks/metrics-logs.html)

### 7.2 Collect request traces using Zipkin

This step shows you how to collect trace spans using [Zipkin](http://zipkin.io).
* Install the required Istio Addon: [Zipkin](http://zipkin.io)
  ```bash
  $ kubectl apply -f install/kubernetes/addons/zipkin.yaml
  ```
* Access your **Zipkin Dashboard**. Get the IP of your cluster `kubectl get nodes` and then the NodePort of your Zipkin service `kubectl get svc | grep zipkin` or you can run the following command to output both:
  ```bash
  $ echo $(kubectl get po -l app=zipkin -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc zipkin -o jsonpath={.spec.ports[0].nodePort})
  184.xxx.yyy.zzz:30XYZ
  ```  
  Your dashboard should like this:
  ![zipkin](images/zipkin.png)

* Send traffic to that service by refreshing your browser to `http://184.xxx.yyy.zzz:30XYZ/productpage` multiple times. You can also do `curl` on your terminal to that URL in a while loop.

* Go to your Zipkin Dashboard again and you will see a number of traces done. _Click on Find Traces button with the appropriate Start and End Time_
![zipkin](images/zipkin-traces.png)
* Click on one those traces and you will see the details of the traffic you sent to your BookInfo App. It shows how much time it took for the request on `productpage`. It also shows how much time ot took for the requests on the `details`,`reviews`, and `ratings` services.
![zipkin](images/zipkin-details.png)

[Zipkin Tracing on Istio](https://istio.io/docs/tasks/zipkin-tracing.html)

# Part C: Enable Egress Traffic for sample application

#### For this part, you should clone this repository to use the YAML files and/or source code for the microservices.

## 8. Create a MySQL Database
Provision Compose for MySQL in Bluemix via https://console.ng.bluemix.net/catalog/services/compose-for-mysql  
Go to Service credentials and view your credentials. Your MySQL hostname, port, user, and password are under your credential uri and it should look like this
![images](images/mysqlservice.png)
## 9. Configure your sample application
In this step, you can choose to build your Docker images from source in the [microservices folder](/microservices) or use the given images.  
The YAML files you need to modify are:  
* `details-new.yaml`
* `reviews-new.yaml`
* `ratings-new.yaml`
* `mysql-data.yaml`
```yaml
spec:
  containers:
  ...
    image: ## <insert the corresponding image name you built>
    imagePullPolicy: IfNotPresent
    env: ## CHANGE THESE VALUES TO YOUR MYSQL DATABASE CREDENTIALS
    - name: MYSQL_DB_USER
      value: 'PLACEHOLDER_DB_USER'
    - name: MYSQL_DB_PASSWORD
      value: 'PLACEHOLDER_DB_PASSWORD'
    - name: MYSQL_DB_HOST
      value: 'PLACEHOLDER_DB_HOST'
    - name: MYSQL_DB_PORT
      value: 'PLACEHOLDER_DB_PORT'
    ...
```

## 10. Inject Istio envoys with Egress traffic enabled on the application
* Insert data in your MySQL database  
```bash
$ kubectl create -f <(istioctl kube-inject -f mysql-data.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
```
The `--includeIPRanges` option is to pass the IP range(s) used for internal cluster services, thereby excluding external IPs from being redirected to the sidecar proxy. The IP range above is for IBM Bluemix provisioned Kubernetes Clusters. For minikube, you will have to use `10.0.0.1/24`
* Deploy `productpage` with Envoy injection and `gateway`.  
```bash
$ kubectl create -f <(istioctl kube-inject -f bookinfo.yaml)
```
The `productpage` is not expecting to have egress traffic so you would not need to configure the Envoy to intercept external requests.

* Deploy `details` with Envoy injection and Egress traffic enabled.  
```bash
$ kubectl create -f <(istioctl kube-inject -f details-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
```
* Deploy `reviews` with Envoy injection and Egress traffic enabled.  
```bash
$ kubectl create -f <(istioctl kube-inject -f reviews-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
```
* Deploy `ratings` with Envoy injection and Egress traffic enabled.  
```bash
$ kubectl create -f <(istioctl kube-inject -f ratings-new.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
```

The `details`, `reviews`, `ratings` will have external traffic since your MySQL database is outside of your cluster. That is why you would need to use `--includeIPRanges` option in `istioctl kube-inject`.

You can now access your application to confirm that it is getting data from your MySQL database.
```bash
echo $(kubectl get po -l istio=ingress -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc istio-ingress -o jsonpath={.spec.ports[0].nodePort})
184.xxx.yyy.zzz:30XYZ
```

Point your browser to:  
`http://184.xxx.yyy.zzz:30XYZ/productpage` Replace with your own IP and NodePort.



[Enabling Egress Traffic on Istio](https://istio.io/docs/tasks/egress.html)

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
