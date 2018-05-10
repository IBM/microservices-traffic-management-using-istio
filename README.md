[![Build Status](https://travis-ci.org/IBM/microservices-traffic-management-using-istio.svg?branch=master)](https://travis-ci.org/IBM/microservices-traffic-management-using-istio)


# Istio: Traffic Management for your Microservices

*Read this in other languages: [한국어](README-ko.md).*

Microservices and containers changed application design and deployment patterns, but along with them brought challenges like service discovery, routing, failure handling, and visibility to microservices. "Service mesh" architecture was born to handle these features. Applications are getting decoupled internally as microservices, and the responsibility of maintaining coupling between these microservices is passed to the service mesh.

[Istio](https://istio.io/), a joint collaboration between IBM, Google and Lyft provides an easy way to create a service mesh that will manage many of these complex tasks automatically, without the need to modify the microservices themselves. Istio does this by:

1. Deploying a **control plane** that manages the overall network infrastructure and enforces the policy and traffic rules defined by the devops team

2. Deploying a **data plane** which includes “sidecars”, secondary containers that sit along side of each instance of a microservice and act as a proxy to intercept all incoming and outgoing network traffic. Sidecars are implemented using Envoy, an open source edge proxy

Once Istio is installed some of the key feature which it makes available include

- Traffic management using **Istio Pilot**: In addition to providing content and policy based load balancing and routing, Pilot also maintains a canonical representation of services in the mesh.

- Access control using **Istio Auth**: Istio Auth secures the service-to-service communication and also provides a key management system to manage keys and certificates.

- Monitoring, reporting and quota management using **Istio Mixer**: Istio Mixer provides in depth monitoring and logs data collection for microservices, as well as collection of request traces. Precondition checking like whether the service consumer is on whitelist, quota management like rate limits etc. are also configured using Mixer.

In the [first part](#part-a-deploy-sample-bookinfo-application-and-inject-istio-sidecars-to-enable-traffic-flow-management-access-policy-and-monitoring-data-aggregation-for-application) of this journey we show how we can deploy the sample [BookInfo](https://istio.io/docs/samples/bookinfo.html) application and inject sidecars to get the Istio features mentioned above, and walk through the key ones. The BookInfo is a simple application that is composed of four microservices, written in different languages for each of its microservices namely Python, Java, Ruby, and Node.js. The application does not use a database, and stores everything in local filesystem.

Also since Istio tightly controls traffic routing to provide above mentioned benefits, it introduces some drawbacks. Outgoing traffic to external services outside the Istio data plane can only be enabled by specialized configuration, based on the protocol used to connect to the external service.

In the [second part](#part-b-modify-sample-application-to-use-an-external-datasource-deploy-the-application-and-istio-envoys-with-egress-traffic-enabled) of the journey we focus on how Istio can be configured to allow applications to connect to external services. For that we modify the sample BookInfo application to use an external database and then use it as a base to show Istio configuration for enabling egress traffic.

![istio-architecture](images/istio-architecture.png)

## Included Components
- [Istio](https://istio.io/)
- [Kubernetes Clusters](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov)
- [Grafana](http://docs.grafana.org/guides/getting_started)
- [Zipkin](http://zipkin.io/)
- [Prometheus](https://prometheus.io/)
- [Bluemix DevOps Toolchain Service](https://console.ng.bluemix.net/catalog/services/continuous-delivery)

# Prerequisite
Create a Kubernetes cluster with either [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) for local testing, with [IBM Cloud Private](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/README.md), or with [IBM Bluemix Container Service](https://github.com/IBM/container-journey-template/blob/master/README.md) to deploy in cloud. The code here is regularly tested against [Kubernetes Cluster from Bluemix Container Service](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov) using Travis.

Create a working directory to clone this repo and to download Istio into:

```bash
$ mkdir ibm
$ cd ibm
$ git clone https://github.com/IBM/traffic-management-for-your-microservices-using-istio.git demo
```

You will also need Istio service mesh installed on top of your Kubernetes cluster.
Here are the steps (Make sure to change the version to your downloaded one):

```bash
$ curl -L https://git.io/getLatestIstio | sh -
$ mv istio-0.7.1 istio
$ export PATH=$PWD/istio/bin:$PATH
$ kubectl apply -f istio/install/kubernetes/istio.yaml

```


# Steps

### Part A: Deploy sample Bookinfo application and inject Istio sidecars to enable traffic flow management, access policy and monitoring data aggregation for application

1. [Deploy sample BookInfo application with Istio sidecar injected](#1-deploy-sample-bookinfo-application-with-istio-sidecar-injected)
2. [Configure Traffic flow](#2-traffic-flow-management-using-istio-pilot---modify-service-routes)
3. [Configure access control](#3-access-policy-enforcement-using-istio-mixer---configure-access-control)
4. [Collect metrics, logs and trace spans](#4-telemetry-data-aggregation-using-istio-mixer---collect-metrics-logs-and-trace-spans)
     - 4.1 [Collect metrics and logs using Prometheus and Grafana](#41-collect-metrics-and-logs-using-prometheus-and-grafana)
     - 4.2 [Collect request traces using Zipkin](#42-collect-request-traces-using-zipkin)

### Part B: Modify sample application to use an external datasource, deploy the application and Istio envoys with egress traffic enabled
5. [Create an external datasource for the application](#5-create-an-external-datasource-for-the-application)
6. [Modify sample application to use the external database](#6-modify-sample-application-to-use-the-external-database)
7. [Deploy application microservices and Istio envoys with egress traffic enabled](#7-deploy-application-microservices-and-istio-envoys-with-egress-traffic-enabled)

## Part A: Deploy sample Bookinfo application and inject Istio sidecars to enable traffic flow management, access policy and monitoring data aggregation for application

## 1. Deploy sample BookInfo application with Istio sidecar injected

In this part, we will be using the sample BookInfo Application that comes as default with Istio code base. As mentioned above, the application that is composed of four microservices, written in different languages for each of its microservices namely Python, Java, Ruby, and Node.js. The default application doesn't use a database and all the microservices store their data in the local file system.
Envoys are deployed as sidecars on each microservice. Injecting Envoy into your microservice means that the Envoy sidecar would manage the ingoing and outgoing calls for the service. To inject an Envoy sidecar to an existing microservice configuration, do:

```bash
$ kubectl apply -f <(istioctl kube-inject -f istio/samples/bookinfo/kube/bookinfo.yaml)
```

> `istioctl kube-inject` modifies the yaml file passed in _-f_. This injects Envoy sidecar into your Kubernetes resource configuration. The only resources updated are Job, DaemonSet, ReplicaSet, and Deployment. Other resources in the YAML file configuration will be left unmodified.

After a few minutes, you should now have your Kubernetes Pods running and have an Envoy sidecar in each of them alongside the microservice. The microservices are **productpage, details, ratings, and reviews**. Note that you'll have three versions of the reviews microservice.
```
$ kubectl get pods

NAME                                        READY     STATUS    RESTARTS   AGE
details-v1-1520924117-48z17                 2/2       Running   0          6m
productpage-v1-560495357-jk1lz              2/2       Running   0          6m
ratings-v1-734492171-rnr5l                  2/2       Running   0          6m
reviews-v1-874083890-f0qf0                  2/2       Running   0          6m
reviews-v2-1343845940-b34q5                 2/2       Running   0          6m
reviews-v3-1813607990-8ch52                 2/2       Running   0          6m
```
To access your application, you can check the public IP address of your application. In the `bookinfo.yaml` file we have configured an ingress resource. Run:

```bash
$ kubectl get ingress -o wide
```
The output is something like
```bash
NAME      HOSTS     ADDRESS                 PORTS     AGE
gateway   *         184.211.10.121          80        1d
```
Set the env variable (change to your output):
```bash
export GATEWAY_URL=184.xxx.xxx.xxx:80
```
Now you can access your application via:`http://${GATEWAY_URL}/productpage`

If you refresh the page multiple times, you'll see that the _reviews_ section of the page changes. That's because there are 3 versions of **reviews**_(reviews-v1, reviews-v2, reviews-v3)_ deployment for our **reviews** service. Istio’s load-balancer is using a round-robin algorithm to iterate through the 3 instances of this service

![productpage](images/none.png)
![productpage](images/black.png)
![productpage](images/red.png)

## 2. Traffic flow management using Istio Pilot - Modify service routes

In this section, Istio will be configured to dynamically modify the network traffic between some of the components of our application. In this case we have 2 versions of the “reviews” component (v1 and v2) but we don’t want to replace review-v1 with review-v2 immediately. In most cases, when components are upgraded it’s useful to deploy the new version but only have a small subset of network traffic routed to it so that it can be tested before the old version is removed. This is often referred to as “canary testing”.

There are multiple ways in which we can control this routing. It can be based on which user is accessing it, or certain percentage of the traffic can be configured to flow to one version etc.

This step shows you how to configure where you want your service requests to go based on weights and HTTP Headers. You would need to be in the root directory of the Istio release you have downloaded on the Prerequisites section.

* Set Default Routes to `reviews-v1` for all microservices  

This would set all incoming routes on the services (indicated in the line `destination: <service>`) to the deployment with a tag `version: v1`. To set the default routes, run:

  ```bash
  $ istioctl create -f istio/samples/bookinfo/kube/route-rule-all-v1.yaml
  ```

* Set Route to `reviews-v2` of **reviews microservice** for a specific user  

This would set the route for the user `jason` (You can login as _jason_ with any password in your deploy web application) to see the `version: v2` of the reviews microservice. Run:

  ```bash
  $ istioctl create -f istio/samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
  ```

* Route 50% of traffic on **reviews microservice** to `reviews-v1` and 50% to `reviews-v3`.  

This is indicated by the `weight: 50` in the yaml file.

  > Using `replace` should allow you to edit existing route-rules.

  ```bash
  $ istioctl replace -f istio/samples/bookinfo/kube/route-rule-reviews-50-v3.yaml

  ```

* Route 100% of the traffic to the `version: v3` of the **reviews microservices**  

This would set every incoming traffic to the version v3 of the reviews microservice. Run:

  ```bash
  $ istioctl replace -f istio/samples/bookinfo/kube/route-rule-reviews-v3.yaml
  ```

## 3. Access policy enforcement using Istio Mixer - Configure access control

This step shows you how to control access to your services. If you have done the step above, you'll see that your `productpage` now just shows red stars on the reviews section and if you are logged in as _jason_, you'll see black stars. The `ratings` service is accessed from the `reviews-v2` if you're logged in as _jason_ or it is accessed from `reviews-v3` if you are not logged in as `jason`.

* To deny access to the ratings service from the traffic coming from `reviews-v3`, you will use `istioctl mixer rule create`

  ```bash
  $ istioctl create -f istio/samples/bookinfo/kube/mixer-rule-ratings-denial.yaml
  ```

* To verify if your rule has been enforced, point your browser to your BookInfo Application, you wouldn't see star ratings anymore from the reviews section unless you are logged in as _jason_ which you will still see black stars (because you would be using the reviews-v2 as you have done in [Step 2](#2-traffic-flow-management-using-istio-pilot---modify-service-routes)).

![access-control](images/access.png)


## 4. Telemetry data aggregation using Istio Mixer - Collect metrics, logs and trace spans

### 4.1 Collect metrics and logs using Prometheus and Grafana

This step shows you how to configure [Istio Mixer](https://istio.io/docs/concepts/policy-and-control/mixer.html) to gather telemetry for services in your cluster.

* Install the required Istio Addons on your cluster: [Prometheus](https://prometheus.io) and [Grafana](https://grafana.com)
  ```bash
  $ kubectl apply -f istio/install/kubernetes/addons/prometheus.yaml
  $ kubectl apply -f istio/install/kubernetes/addons/grafana.yaml
  ```
* Verify that your **Grafana** dashboard is ready. Get the IP of your cluster `bx cs workers <your-cluster-name>` and then the NodePort of your Grafana service `kubectl get svc | grep grafana` or you can run the following command to output both:

  ```bash
  $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana \
  -o jsonpath='{.items[0].metadata.name}') 3000:3000
  ```
  Point your browser to http://localhost:3000  

  Your dashboard should look like this:  
  ![Grafana-Dashboard](images/grafana.png)

* To collect new telemetry data, you will apply a mixer rule. For this sample, you will generate logs for Response Size for Reviews service. The configuration YAML file is provided within the BookInfo sample folder.

* Create the configuration on Istio Mixer using the configuration in [new-metrics-rule.yaml](new-metrics-rule.yaml)
`
  ```bash
  $ istioctl create -f demo/new_telemetry.yaml
  ```

* Send traffic to that service by refreshing your browser to `http://${GATEWAY_URL}/productpage` multiple times. You can also do `curl` on your terminal to that URL in a while loop.

  ```bash
  $ for i in {1..5}; do echo -n .; curl -s http://${GATEWAY_URL}/productpage > /dev/null; done
  ```

* Verify that the new metric is being collected by going to your Grafana dashboard again. The graph on the rightmost should now be populated.

![grafana-new-metric](images/grafana-new-metric.png)

* Verify that the logs stream has been created and is being populated for requests

  ```bash
  $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio=mixer -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"

  {"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
  ...
  ```

[Collecting Metrics and Logs on Istio](https://istio.io/docs/tasks/telemetry/metrics-logs.html)

### 4.2 Collect request traces using Zipkin

This step shows you how to collect trace spans using [Zipkin](http://zipkin.io).
* Install the required Istio Addon: [Zipkin](http://zipkin.io)

  ```bash
  $ kubectl apply -f istio/install/kubernetes/addons/zipkin.yaml
  ```

* Access your **Zipkin Dashboard**. Get the IP of your cluster `bx cs workers <your-cluster-name>` and then the NodePort of your Zipkin service `kubectl get svc | grep zipkin` or you can run the following command to output both:
  ```bash
  $ kubectl port-forward -n istio-system \
  $(kubectl get pod -n istio-system -l app=zipkin -o jsonpath='{.items[0].metadata.name}') \
  9411:9411
  ```  
  Access the zipkin dashboard `http://localhost:3000`

  Your dashboard should like this:
  ![zipkin](images/zipkin.png)

* Send traffic to that service by refreshing your browser to `http://${GATEWAY_URL}/productpage` multiple times. You can also do reuse the `curl` for loop from earlier.

* Go to your Zipkin Dashboard again and you will see a number of traces done. _Click on Find Traces button with the appropriate Start and End Time_

![zipkin](images/zipkin-traces.png)

* Click on one of those traces and you will see the details of the traffic you sent to your BookInfo App. It shows how much time it took for the request on `productpage` to finish. It also shows how much time it took for the requests on the `details`,`reviews`, and `ratings` services.

![zipkin](images/zipkin-details.png)

[Zipkin Tracing on Istio](https://istio.io/docs/tasks/telemetry/distributed-tracing.html)

## Part B:  Modify sample application to use an external datasource, deploy the application and Istio envoys with egress traffic enabled

In this part, we will modify the sample BookInfo application to use use an external database, and enable the Istio envoys for egress traffic. Please ensure you have the Istio control plane installed on your Kubernetes cluster as mentioned in the prerequisites. We will run these commands from the outside the `demo folder we cloned the source code repository in at the beginning.

## 5. Create an external datasource for the application

Provision Compose for MySQL in Bluemix via https://console.ng.bluemix.net/catalog/services/compose-for-mysql  
Go to Service credentials and view your credentials. Your MySQL hostname, port, user, and password are under your credential uri and it should look like this
![images](images/mysqlservice.png)

## 6. Modify sample application to use the external database

In this step, the original sample BookInfo Application is modified to leverage a MySQL database. The modified microservices are the `details`, `ratings`, and `reviews`. This is done to show how Istio can be configured to enable egress traffic for applications leveraging external services outside the Istio data plane, in this case a database.

In this step, you can either choose to build your Docker images for different microservices from source in the [microservices folder](/microservices) or use the given images.
> For building your own images, go to [microservices folder](/microservices)

The following modifications were made to the original Bookinfo application. The **details microservice** is using Ruby and a `mysql` ruby gem was added to connect to a MySQL database. The **ratings microservice** is using Node.js and a `mysql` module was added to connect to a MySQL database. The **reviews v1,v2,v3 microservices** is using Java and a `mysql-connector-java` dependency was added in [build.gradle](/microservices/reviews/reviews-application/build.gradle) to connect to a MySQL database. More source code was added to [details.rb](/microservices/details/details.rb), [ratings.js](/microservices/ratings/ratings.js), [LibertyRestEndpoint.java](/microservices/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java) that enables the application to use the details, ratings, and reviews data from the MySQL Database.  

Preview of added source code for `ratings.js` for connecting to MySQL database:
![ratings_diff](images/ratings_diff.png)


You will need to update the `demo/secrets.yaml` file to include the credentials provided by Bluemix Compose.

> Note: The values provided in the secrets file should be run through `base64` first.

```bash
echo -n <username> | base64
echo -n <password> | base64
echo -n <host> | base64
echo -n <port> | base64
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-credentials
type: Opaque
data:
  username: YWRtaW4=
  password: VEhYTktMUFFTWE9BQ1JPRA==
  host: c2wtdXMtc291dGgtMS1wb3J0YWwuMy5kYmxheWVyLmNvbQ==
  port: MTg0ODE=
```

Once the secrets are set add them to your Kubernetes cluster:

```bash
$ kubectl apply -f demo/secrets.yaml
```

## 7. Deploy application microservices and Istio envoys with Egress traffic enabled

By default, Istio-enabled applications will be unable to access URLs outside of the cluster. All outbound traffic in the pod are redirected by its sidecar proxy which only handles destinations inside the cluster.


There are two ways to configure Istio to expose external services to Istio-enabled clients. a. by defining `ExternalService` configurations, or b. simply bypass the Istio proxy for a specific range of IPs. In this exercise, we'll use the ip range.

We'll save the ip range in an environment variable so that we can reuse:

```bash
$ export IPRANGES=172.30.0.0/16,172.20.0.0/16
$ echo $IPRANGES
```

* Insert data in your MySQL database in Bluemix.
> This inserts the database design and initial data for the database.

```bash
$ kubectl apply -f demo/mysql-data.yaml
```

* Deploy `productpage` with Envoy injection and `gateway`.  

```bash
$ kubectl apply -f <(istioctl kube-inject -f demo/bookinfo.yaml)

```
The `productpage` is not expecting to have egress traffic so you would not need to configure the Envoy to intercept external requests.

* Deploy `details` with Envoy injection and Egress traffic enabled.  

```bash
$ kubectl apply -f <(istioctl kube-inject -f demo/details-new.yaml --includeIPRanges=${IPRANGES})
```

* Deploy `reviews` with Envoy injection and Egress traffic enabled.  

```bash
$ kubectl apply -f <(istioctl kube-inject -f demo/reviews-new.yaml --includeIPRanges=${IPRANGES})
```

* Deploy `ratings` with Envoy injection and Egress traffic enabled.  

```bash
$ kubectl apply -f <(istioctl kube-inject -f demo/ratings-new.yaml --includeIPRanges=${IPRANGES})
```

The `details`, `reviews`, `ratings` will have external traffic since your MySQL database is outside of your cluster. That is why you would need to use `--includeIPRanges` option in `istioctl kube-inject`.

You can now access your application to confirm that it is getting data from your MySQL database.
Point your browser to:  
`http://${GATEWAY_URL}/productpage`

# Troubleshooting
* To delete Istio from your cluster

```bash
$ kubectl delete -f install/kubernetes/istio.yaml
```

* To delete all addons: `kubectl delete -f install/kubernetes/addons`
* To delete the BookInfo app and its route-rules: `./samples/apps/bookinfo/cleanup.sh`

# References
[Istio.io](https://istio.io/docs/tasks/)
# License
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)
