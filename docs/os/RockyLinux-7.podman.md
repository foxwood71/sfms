# Rocky Linux 9 Podman + k3s 설치 및 운영 가이드

Rocky Linux 9에서 Podman으로 컨테이너를 관리하고, Kubernetes 경량 배포판인 k3s로 오케스트레이션하는 방법을 정리합니다.

---

## 1. 사전 준비

```bash
sudo dnf update -y
sudo dnf install -y dnf-utils yum-utils
```

- 최소 사양: CPU 2코어 이상, RAM 4GB 이상 권장
- 방화벽을 사용하는 경우 k3s 포트(6443 등) 허용 필요(wsl 환경에서는 불필요함)

---

## 2. Podman 설치 및 기본 설정

Rocky Linux 9 기본 리포지토리에 Podman이 포함되어 있어 추가 repo 없이 설치 가능합니다.[file:1]

```bash
sudo dnf install -y podman podman-docker containers-common
```

- `podman-docker`: `docker` 명령을 Podman으로 전달하는 shim 패키지
- `containers-common`: 컨테이너 공통 설정 파일, 스토리지 설정 등

### 2.1 Podman 소켓 활성화 (선택)

일부 툴에서 Docker 소켓(`/var/run/docker.sock`)을 기대하는 경우 Podman 소켓을 켜둡니다.[file:1]

```bash
# 일반 사용자 기준(rootless)
systemctl --user enable --now podman.socket
systemctl --user status podman.socket

# root 기준(필요 시)
sudo systemctl enable --now podman.socket
sudo systemctl status podman.socket
```

### 2.2 설치 확인

```bash
podman --version
podman info

# podman-docker 설치 시
docker --version   # Podman shim
docker info
```

---

## 3. Podman 기본 사용 예시

### 3.1 컨테이너/이미지/볼륨

```bash
# 이미지
podman pull nginx:alpine
podman images
podman rmi nginx:alpine

# 컨테이너
podman run -d --name web -p 80:80 nginx
podman ps -a
podman stop web
podman rm web

# 볼륨
podman volume create data
podman run -d --name web2 -p 8080:80 -v data:/usr/share/nginx/html nginx
```

SELinux 활성 환경에서는 볼륨 마운트 시 `:Z` 또는 `:z` 옵션 사용을 권장합니다.[file:1]

```bash
podman run -d --name web \
  -p 8080:80 \
  -v /srv/web:/usr/share/nginx/html:Z \
  nginx
```

### 3.2 개발용 워크플로우

```bash
# Node.js 개발 컨테이너 예시
podman run -it --rm \
  -v $(pwd):/app \
  -w /app \
  -p 3000:3000 \
  node:20 bash
```

---

## 4. k3s(경량 Kubernetes) 개요

k3s는 단일 바이너리로 구성된 경량 Kubernetes 배포판으로, Edge/개발/소규모 운영 환경에 적합합니다.

특징:
- 설치 명령 한 줄로 클러스터 구성 가능
- 기본적으로 Traefik Ingress, 로컬 스토리지 드라이버 포함
- etcd 또는 SQLite를 데이터스토어로 사용

---

## 5. k3s 단일 노드 클러스터 설치

### 5.1 요구 사항

- Root 권한 또는 sudo 권한
- 포트: 6443(TCP) 등 Kubernetes 관련 포트 허용
- Swap 비활성화 권장

```bash
# swap 비활성화 (권장)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 5.2 설치 스크립트 실행

* 실제서버 (SELinux 활성 상태)
```bash
sudo dnf install -y yum
sudo dnf install -y selinux-policy-targeted selinux-policy container-selinux
sudo dnf install -y https://rpm.rancher.io/k3s/stable/common/centos/9/noarch/k3s-selinux-1.6-1.el9.noarch.rpm
curl -sfL https://get.k3s.io | sudo sh -
```
* wsl 환경설정 (SELinux 비활성 상태)
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_SELINUX_RPM=true sh -
```

* 일반 사용자 권한 설정
```bash
# .kube 디렉토리 생성
mkdir -p ~/.kube

# K3s 설정 파일을 사용자 홈 디렉토리로 복사
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# 파일 소유권을 현재 사용자에게 부여
sudo chown $USER:$USER ~/.kube/config

# 환경 변수에 등록 (선택 사항: .bashrc나 .zshrc에 추가 권장)
export KUBECONFIG=~/.kube/config
```

설치가 완료되면 `k3s` 서버가 systemd 서비스로 등록되고, `kubectl` 호환 바이너리가 `/usr/local/bin/kubectl` 혹은 `k3s kubectl` 형태로 제공됩니다.[file:1]

### 5.3 상태 확인

```bash
sudo systemctl status k3s

# kubectl 링크가 있는 경우
kubectl get nodes

# 없는 경우
sudo k3s kubectl get nodes
```

---

## 6. k3s 노드/토큰 정보 및 멀티 노드 확장

### 6.1 토큰 확인 (서버 노드)

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

### 6.2 워커 노드 추가

워커 노드(추가 Rocky Linux 서버)에서 다음을 실행합니다.[file:1]

```bash
export K3S_URL="https://<MASTER_IP>:6443"
export K3S_TOKEN="<위에서 확인한 node-token>"

curl -sfL https://get.k3s.io | \
  K3S_URL=$K3S_URL \
  K3S_TOKEN=$K3S_TOKEN \
  sh -
```

클러스터에서 노드 확인:

```bash
kubectl get nodes
```

---

## 7. k3s 방화벽 설정 (firewalld 사용 시)

서버 노드에서 Kubernetes 관련 포트를 허용합니다.[file:1]

```bash
sudo firewall-cmd --add-port=6443/tcp --permanent     # API 서버
sudo firewall-cmd --add-port=8472/udp --permanent     # VXLAN (오버레이 네트워크)
sudo firewall-cmd --add-port=10250/tcp --permanent    # kubelet
sudo firewall-cmd --reload
```

외부에서 Ingress(HTTP/HTTPS) 접근을 위해 80, 443 포트도 허용합니다.[file:1]

```bash
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload
```

---

## 8. 예제: Nginx Deployment + Service 배포

### 8.1 매니페스트 작성 (`nginx-deploy.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
***
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer    # k3s에서는 NodePort + 로컬 LB로 동작
  selector:
    app: nginx-demo
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080   # 선택: NodePort 고정
```

### 8.2 배포 및 확인

```bash
kubectl apply -f nginx-deploy.yaml

kubectl get deployments
kubectl get pods -o wide
kubectl get svc
```

단일 노드 환경에서는:

```bash
curl http://127.0.0.1:30080
# 또는
curl http://<노드 IP>:30080
```

---

## 9. 예제: Ingress 사용 (도메인 기반 라우팅)

k3s 기본 설치에는 Traefik Ingress Controller가 포함되어 있으므로 바로 Ingress 리소스를 사용할 수 있습니다.[file:1]

### 9.1 Ingress 매니페스트 (`nginx-ingress.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-demo-ingress
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: nginx.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```

### 9.2 배포 및 접속

```bash
kubectl apply -f nginx-ingress.yaml
kubectl get ingress
```

로컬 PC의 `/etc/hosts`에 다음을 추가합니다.

```text
<노드 IP>  nginx.local
```

이후 브라우저 또는 curl로 접속합니다.

```bash
curl http://nginx.local
```

---

## 10. Kubernetes Secret을 이용한 민감정보 관리 (MySQL 예제)

Docker Swarm Secret 대신 Kubernetes Secret으로 DB 비밀번호 등을 관리합니다.[file:1]

### 10.1 Secret 생성

```bash
# 문자열로 직접 생성 (base64 인코딩은 kubectl이 처리)
kubectl create secret generic mysql-root-password \
  --from-literal=MYSQL_ROOT_PASSWORD=my_password123

kubectl get secrets
```

### 10.2 Deployment/Service 매니페스트 (`mysql-deploy.yaml`)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
***
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:8.0
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-root-password
                  key: MYSQL_ROOT_PASSWORD
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-data
          persistentVolumeClaim:
            claimName: mysql-pvc
***
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  type: ClusterIP
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
```

배포:

```bash
kubectl apply -f mysql-deploy.yaml

kubectl get pods
kubectl get svc
kubectl get pvc
```

---

## 11. k3s 관리 치트시트

### 11.1 기본 명령어

```bash
# 노드, 네임스페이스
kubectl get nodes
kubectl get ns

# 워크로드
kubectl get pods -A
kubectl get deployments -A
kubectl get svc -A
kubectl get ingress -A

# 상세 보기
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- bash
```

### 11.2 리소스 적용/삭제

```bash
kubectl apply -f <file>.yaml
kubectl delete -f <file>.yaml
```

### 11.3 네임스페이스 활용

```bash
kubectl create ns dev
kubectl apply -n dev -f app.yaml

kubectl get pods -n dev
```

---

## 12. k3s 서비스 관리 및 제거

### 12.1 서비스 재시작/로그

```bash
sudo systemctl status k3s
sudo systemctl restart k3s
sudo journalctl -u k3s -f
```

### 12.2 k3s 완전 제거 (주의)

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## 13. Podman + k3s 조합 사용 팁

- **Podman**: 로컬 개발용 컨테이너 실행, 이미지 빌드, 테스트에 사용
- **k3s(Kubernetes)**: 실제 서비스 오케스트레이션, 롤링 업데이트, 오토스케일링(HPA) 구성에 사용
- 이미지 빌드는 Podman으로 하고, registry에 push 후 k3s에서 `image: <registry>/<repo>:tag`로 사용하면 됩니다.[file:1]

예시:

```bash
# 1. Podman으로 이미지 빌드
podman build -t registry.local:5000/myapp:v1 .

# 2. 레지스트리에 push
podman push registry.local:5000/myapp:v1

# 3. k3s Deployment에서 사용
# spec.template.spec.containers[].image: registry.local:5000/myapp:v1
kubectl set image deployment/myapp myapp=registry.local:5000/myapp:v1
```

---

**핵심 요약:**  
- 단일 노드: Podman으로 개발/테스트 → k3s로 배포/운영  
- 멀티 노드: k3s 서버 + 워커 노드 구성, `kubectl`로 전체 클러스터 관리  
- Secret, PVC, Ingress를 조합하면 대부분의 웹서비스/DB 시나리오를 구현할 수 있습니다.[file:1]
```