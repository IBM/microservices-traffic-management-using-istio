[![Build Status](https://travis-ci.org/IBM/ISTIO-Service-Mesh-on-Kubernetes.svg?branch=master)](https://travis-ci.org/IBM/ISTIO-Service-Mesh-on-Kubernetes)

# Conenct, Manage and secure microservices leveraging ISTIO Service Mesh on Kubernetes

[Istio](http://istio.io) is an open platform that provides a uniform way to connect, manage, and secure microservices. Istio is the result of a joint collaboration between IBM, Google and Lyft as a means to support traffic flow management, access policy enforcement and the telemetry data aggregation between microservices, all without requiring changes to the code of your microservice. Istio provides an easy way to create this service mesh by deploying a [control plane](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) and injecting sidecars, an extended version of the  [Envoy](https://lyft.github.io/envoy/) proxy, in the same Pod as your microservice.
 
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
5. [Collecting Metrics and Logs](#5-collecting-metrics-and-logs)
6. [Request Tracing](#6-request-tracing)

#### [Troubleshooting](#troubleshooting-1)

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
# 5. Collecting Metrics and Logs
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
# 6. Request Tracing
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

* Go to your Zipkin Dashboard again and you will see a number of traces done.
![zipkin](images/zipkin-traces.png)
* Click on one those traces and you will see the details of the traffic you sent to your BookInfo App. It shows how much time it took for the request on `productpage`. It also shows how much time ot took for the requests on the `details`,`reviews`, and `ratings` services.
![zipkin](images/zipkin-details.png)

[Zipkin Tracing on Istio](https://istio.io/docs/tasks/zipkin-tracing.html)

# Troubleshooting
* To delete Istio from your cluster
```bash
$ kubectl delete -f install/kubernetes/istio-rbac-alpha.yaml # or istio-rbac-beta.yaml
$ kubectl delete -f install/kubernetes/istio.yaml
```
* To delete all addons: `kubectl delete -f install/kubernetes/addons`
* To delete the BookInfo app and its route-rules: `./samples/apps/bookinfo/cleanup.sh`

# References
[Istio.io](https://istio.io/docs/tasks/index.html)
# License
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)
