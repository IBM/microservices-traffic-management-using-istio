# 쿠버네티스 클러스터에 Istio 서비스 메쉬 배포하기

*다른 언어로 보기: [English](GETTING_STARTED).*

[Istio](http://istio.io)는 마이크로 서비스에 대한 연결, 관리 및 보안 기능을 통일된 방식으로 제공하는 오픈 플랫폼입니다. Istio는 IBM, Google 그리고 Lyft의 협업의 결과이며, 트래픽 흐름 관리, 접근 정책 강제 그리고 마이크로 서비스간 측정 데이터 수집을 해당 마이크로 서비스의 코드 수정없이 지원합니다. Istio는 이러한 서비스 메쉬를 쉽게 생성하도록 [컨트롤 플레인(control plane)](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture)을 배포하고 해당 마이크로 서비스에 대한 Pod와 동일한 Pod에 [Envoy](https://lyft.github.io/envoy/)의 확장 버전인 사이드카를 주입합니다.

# 전제 조건
로컬 테스트용으로 [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube)를 사용하거나, 클라우드 배포용 으로 [IBM Bluemix Container 서비스](https://github.com/IBM/container-journey-template/blob/master/README.md)를 사용하여 쿠버네티스 클러스터를 생성하십시오.

# 단계

## 쿠버네티스 클러스터에 Istio 서비스 메쉬 배포하기

## 1. 쿠버네티스에 Istio 설치하기

### 1.1 Istio 소스 다운로드하기

  > 참고: 이 예제는 istio 0.1.6에서 테스트된 것으로, 일관성을 위해 이 버전을 사용할 것을 추천합니다.
    지정된 위치에 파일들을 풀어놓아야 지침에 있는 명령 구문이 정상 실행됩니다.

  1. OS에 맞는 Istio 릴리즈를 다운로드 하십시오: [Istio 릴리즈](https://github.com/istio/istio/releases)  
  2. 앞서 만들어 놓았던 `ibm` 디렉토리에 tarball 파일을 풀어놓으십시오.
  3. `istioctl` 바이너리 파일을 실행 가능한 위치로 복사하십시오.

  ```bash
  $ tar xzvf <path-to-istio-download>
  $ mv istio-<VERSION> istio
  $ cp istio/bin/istioctl /usr/local/bin

  ```

### 1.2 권한 부여하기  
  1. RBAC를 갖는 클러스터인지 확인하기 위해 아래 명령을 실행하십시오.  
  ```bash
  $ kubectl api-versions | grep rbac
  ```  
  2. 클러스터의 RBAC 버전에 따라 권한을 부여합니다  
    * **alpha** 버젼인 경우, 다음을 실행하십시오:

      ```bash
      $ kubectl apply -f istio/install/kubernetes/istio-rbac-alpha.yaml
      ```

    * **beta** 버젼인 경우, 다음을 실행하십시오:

      ```bash
      $ kubectl apply -f istio/install/kubernetes/istio-rbac-beta.yaml
      ```

    * **RBAC가 없는 클러스터**인 경우, **컨트롤 플레인** 설치를 진행하십시오.

### 1.3 클러스터에 [Istio 컨트롤 플레인](https://istio.io/docs/concepts/what-is-istio/overview.html#architecture) 설치하기  
  1. 다음 명령을 실행하여 Istio를 설치하십시오.
  ```bash
  $ kubectl apply -f istio/install/kubernetes/istio.yaml
  # or kubectl apply -f istio/install/kubernetes/istio-auth.yaml
  ```
  > `istio-auth.yaml`은  Istio의 [Auth](https://istio.io/docs/concepts/network-and-auth/auth.html) 기능을 활성화 하는 것으로 서비스들 간 [mTLS](https://en.wikipedia.org/wiki/Mutual_authentication)를 활성화합니다

  2. 이제 클러스터의 Pod에서 실행 중인 Istio 컨트롤 플레인을 확인해 볼 수 있습니다.
  ```bash
  $ kubectl get pods
  NAME                              READY     STATUS    RESTARTS
  istio-egress-3850639395-30d1v     1/1       Running   0       
  istio-ingress-4068702052-2st6r    1/1       Running   0       
  istio-pilot-251184572-x9dd4       2/2       Running   0       
  istio-mixer-2499357295-kn4vq      1/1       Running   0       
  ```

# 문제 해결
* 클러스터에서 Istio 삭제하기
```bash
$ kubectl delete -f istio/install/kubernetes/istio-rbac-alpha.yaml # or istio-rbac-beta.yaml
$ kubectl delete -f istio/install/kubernetes/istio.yaml
$ kubectl delete istioconfigs --all
$ kubectl delete thirdpartyresource istio-config.istio.io
```
* 모든 애드온 삭제하기: `kubectl delete -f install/kubernetes/addons`

# 참고
[Istio.io](https://istio.io/docs/tasks/index.html)
# 라이센스
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)
