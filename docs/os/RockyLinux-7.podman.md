# Rocky Linux 10 (Podman 5.6.0) + k3s 종합 설치 및 운영 가이드

Rocky Linux 10 환경에서 최신 Podman 5.6.0으로 컨테이너를 관리하고, Kubernetes 경량 배포판인 k3s로 오케스트레이션하는 전체 과정을 엮은 마스터 문서입니다.

## 0. 전체 프로그램 설치 및 구축 순서 (로드맵)

이 시스템을 처음부터 끝까지 에러 없이 구축하기 위한 작업 순서입니다.

1. **OS 사전 준비:** Rocky 10 시스템 패키지 업데이트 및 기본 유틸리티 설치
2. **Podman 환경 구축:** Podman 5.6.0 설치 및 소켓 활성화 (목적에 따라 Root/Rootless 선택)
3. **Podman 네트워크/방화벽 구성:** 모드별 가상 네트워크 생성 및 방화벽 설정 (Podman 5.x 기본 `pasta` 네트워크 및 WSL 에러 우회 설정 포함)
4. **k3s 사전 준비:** Swap 메모리 비활성화 및 k3s용 호스트 방화벽 개방
5. **k3s 클러스터 설치:** 서버 노드(Master) 설치 및 일반 사용자 `kubectl` 권한 부여
6. **k3s 클러스터 확장 (선택):** 워커 노드 추가 연동
7. **애플리케이션 배포 및 운영:** Podman으로 이미지 빌드 후 k3s를 통해 배포 (PostgreSQL PVC/Secret, Nginx Deployment, Ingress)

---

## 1. Podman: Root vs Rootless 운영 환경 비교 및 선택

설치를 시작하기 전, 컨테이너를 어떤 권한으로 실행할지 결정해야 합니다.

| 구분 | Root 환경 (Rootful) | Rootless 환경 (Rootless) |
| --- | --- | --- |
| **실행 주체** | `root` 계정 (또는 `sudo` 사용) | 일반 사용자 계정 (예: `blue` 등) |
| **보안 (Security)** | 낮음: 뚫리면 호스트 OS의 루트 권한까지 위험. | 매우 높음: 뚫리더라도 해당 유저의 권한 안에 격리됨. |
| **네트워크 모드** | 커널 브리지, `netavark` (방화벽 직접 제어) | 유저 공간 네트워크 프록시 (Podman 5.x 기본: **`pasta`**) |
| **포트 바인딩** | 1~1023 포함 모든 포트 즉시 개방 가능 | 기본적으로 1024 이상의 포트만 개방 (sysctl로 해제 가능) |
| **저장소 위치** | `/var/lib/containers/` (시스템 전체 공유) | `~/.local/share/containers/` (독립 보관, SQLite DB 사용) |
| **파일 소유권** | 컨테이너 Root(0) = 호스트 Root(0) | 컨테이너 Root(0) = 호스트 일반 사용자 (User Namespace) |
| **추천 사용 환경** | 전용 DB/웹 서버, 고성능 네트워크 필요 서버 | WSL 등 개인 개발 환경, 다중 사용자 서버, 보안 최우선 인프라 |

---

## 2. 사전 준비 및 Podman 5.6.0 설치

Rocky Linux 10 환경에서는 최신 Podman 패키지가 기본 제공되거나 모듈을 통해 쉽게 설치할 수 있습니다.

### 2.1 패키지 업데이트 및 설치

```bash
sudo dnf update -y
sudo dnf install -y dnf-utils yum-utils
sudo dnf install -y podman podman-docker containers-common passt
pip3 install podman-compose
```

* `passt`: Podman 5.x의 Rootless 네트워크 기본 백엔드인 `pasta`를 구동하기 위한 필수 패키지입니다.
* `podman-docker`: `docker` 명령을 Podman으로 맵핑합니다.

### 2.2 Podman 소켓 활성화 (선택)

일부 서드파티 툴(Portainer 등)에서 Docker 호환 API 소켓(`/var/run/docker.sock`)을 요구할 때 켭니다.

```bash
# 일반 사용자 기준 (Rootless)
systemctl --user enable --now podman.socket
systemctl --user status podman.socket

# root 기준 (필요 시 / Rootful)
sudo systemctl enable --now podman.socket
sudo systemctl status podman.socket
```

### 2.3 설치 확인 및 기본 명령어

```bash
podman --version  # 5.6.0 버전 확인
podman info

# 볼륨 마운트 시 SELinux 주의사항 (:Z 옵션 필수)
podman run -d --name web \
    -p 8080:80 \
    -v /srv/web:/usr/share/nginx/html:Z \
    nginx:alpine
```

---

## 3. Podman 심화: Compose 및 Containerfile 차이점

### 3.1 compose.yaml 기능 차이

| 기능 | Root 환경 (Rootful) | Rootless 환경 (Rootless) |
| --- | --- | --- |
| **포트 (`ports`)** | 모든 포트 개방 가능 | 기본 1024번 미만 개방 불가 (커널 설정 필요) |
| **시크릿 (`secrets`)** | `uid`, `mode` 옵션을 커널이 완벽하게 즉시 적용 | 무시됨. 호스트에서 미리 `podman unshare`로 권한 세탁 필요 |
| **볼륨 (`volumes`)** | 권한 제약 없이 호스트 폴더에 강제 마운트 | User Namespace 맵핑으로 권한 꼬임 주의 (`:Z` 옵션 필수) |
| **특권 (`privileged`)** | 진짜 호스트 Root 권한 획득 (보안 위험) | 해당 유저 공간 내에서의 최고 권한만 획득 (안전함) |
| **네트워크 (`networks`)** | 실제 커널 브리지를 생성하여 완벽한 통신 지원 | 유저 모드 프록시(`pasta`) 통신을 거치므로 방화벽 우회 필요 |

### 3.2 Containerfile 작성 전략

* **`USER` 지시어:** Root 환경은 마지막에 `USER 1000` 등으로 권한을 낮추는 것이 필수입니다. Rootless 환경은 `root(0)`로 실행하더라도 호스트 일반 사용자로 맵핑되므로 안전합니다.
* **`COPY --chown`:** Rootless 환경에서도 Podman이 가상 권한을 부여하므로 `COPY --chown=999:999` 실행 시 에러가 발생하지 않습니다.

---

## 4. 모드별 사용자 공간 네트워크 구축 및 방화벽 설정

Podman 5.6.0에서는 네트워크 백엔드 구조가 개편되었으므로, 환경에 맞는 세팅이 필수입니다.

### 4.1 Rootful (관리자) 네트워크 구축 및 방화벽

커널 방화벽을 직접 제어하여 진짜 가상 스위치(Bridge)를 생성합니다.

```bash
# 1. 가상 네트워크 생성 (netavark 엔진이 커널 규칙 자동 주입)
sudo podman network create sfms-net

# 2. 호스트 방화벽 개방 (외부 트래픽 허용)
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload
```

*(확인: `ip a` 입력 시 `podman1` 또는 `sfms-net` 등 실제 네트워크 어댑터가 생성됩니다.)*

### 4.2 Rootless (일반 사용자) 네트워크 구축 (pasta 최적화 및 WSL 방화벽 우회)

Podman 5.x부터는 느린 `slirp4netns` 대신 빠르고 IPv6를 완벽 지원하는 **`pasta`**가 기본입니다. 하지만 일반 사용자는 커널 방화벽 권한이 없어 WSL 등에서 에러가 발생할 수 있으므로 설정을 조정해야 합니다.

```bash
# 1. WSL 등 커널 방화벽(nftables) 충돌 에러 방지 및 pasta 명시적 지정
mkdir -p ~/.config/containers
nano ~/.config/containers/containers.conf
# --- 파일 내용 시작 ---
[network]
# 커널 방화벽 드라이버 비활성화 (netavark/nftables Permission 에러 방지)
firewall_driver = "none"

# Podman 5.x의 고성능 네트워크 백엔드인 pasta 명시적 지정
default_rootless_network_cmd = "pasta"
# --- 파일 내용 끝 ---

# 2. 가상 네트워크 생성 (호스트 어댑터 없이 유저 공간에 생성됨)
podman network prune -f  # 꼬인 기존 네트워크 초기화
podman network create sfms-net

# 3. 1024 미만 포트 바인딩 커널 허용 및 외부 방화벽 개방
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee /etc/sysctl.d/99-rootless-ports.conf
sudo sysctl --system

sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload
```

---

## 5. k3s (경량 Kubernetes) 사전 준비 및 설치

### 5.1 사전 요구 사항 및 방화벽 설정

* **Swap 비활성화 (필수 권장):**

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

* **k3s 내부 통신 포트 개방:**

```bash
sudo firewall-cmd --add-port=6443/tcp --permanent     # API 서버
sudo firewall-cmd --add-port=8472/udp --permanent     # VXLAN (오버레이 네트워크)
sudo firewall-cmd --add-port=10250/tcp --permanent    # kubelet
sudo firewall-cmd --add-service=http --permanent      # Ingress (80)
sudo firewall-cmd --add-service=https --permanent     # Ingress (443)
sudo firewall-cmd --reload
```

### 5.2 k3s 클러스터 설치 스크립트 실행

* **Rocky 10 실제 서버 (SELinux 활성 상태):**

```bash
sudo dnf install -y yum selinux-policy-targeted selinux-policy container-selinux
sudo dnf install -y https://rpm.rancher.io/k3s/stable/common/centos/9/noarch/k3s-selinux-1.6-1.el9.noarch.rpm
curl -sfL https://get.k3s.io | sudo sh -
```

* **WSL 환경 (SELinux 비활성 상태):**

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_SELINUX_RPM=true sh -
```

### 5.3 일반 사용자 권한 설정 (kubeconfig)

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config  # ~/.bashrc 에 추가
```

---

## 6. k3s 멀티 노드 확장 (선택 사항)

1. **마스터 노드에서 토큰 확인:**

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

1. **워커 노드 연동 스크립트 실행:**

```bash
export K3S_URL="https://<MASTER_IP>:6443"
export K3S_TOKEN="<위에서 확인한 node-token>"
curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -
```

---

## 7. 실전 k3s 배포 예제 (PostgreSQL, Nginx, Ingress)

### 7.1 PostgreSQL (PVC 및 Secret 활용) 배포 (`postgres-deploy.yaml`)

DB 접속용 비밀번호를 Kubernetes Secret으로 안전하게 관리하고 스토리지를 마운트합니다.

```bash
# 문자열로 직접 Secret 생성 (Base64 자동 인코딩)
kubectl create secret generic postgres-secret \
    --from-literal=POSTGRES_PASSWORD=my_password123
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: postgres-pvc
spec:
    accessModes:
        - ReadWriteOnce
    resources:
        requests:
            storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: postgres
spec:
    replicas: 1
    selector:
        matchLabels:
            app: postgres
    template:
        metadata:
            labels:
                app: postgres
        spec:
            containers:
                - name: postgres
                  image: postgres:16
                  ports:
                      - containerPort: 5432
                  env:
                      - name: POSTGRES_PASSWORD
                        valueFrom:
                            secretKeyRef:
                                name: postgres-secret
                                key: POSTGRES_PASSWORD
                  volumeMounts:
                      - name: postgres-data
                        mountPath: /var/lib/postgresql/data
            volumes:
                - name: postgres-data
                  persistentVolumeClaim:
                      claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
    name: postgres
spec:
    type: ClusterIP
    selector:
        app: postgres
    ports:
        - port: 5432
          targetPort: 5432
```

`kubectl apply -f postgres-deploy.yaml`

### 7.2 Nginx Deployment + Ingress 배포 (`nginx-ingress.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: nginx-deployment
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
---
apiVersion: v1
kind: Service
metadata:
    name: nginx-service
spec:
    type: ClusterIP
    selector:
        app: nginx-demo
    ports:
        - port: 80
          targetPort: 80
---
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

배포 후 로컬 PC `/etc/hosts`에 `<노드 IP> nginx.local` 추가 후 브라우저로 접속 확인.

---

## 8. k3s 관리 치트시트 및 완전 제거

### 8.1 네임스페이스 활용 및 모니터링

```bash
kubectl get nodes                # 노드 확인
kubectl get pods -A              # 전체 파드 확인
kubectl get pvc                  # 스토리지 볼륨 상태 확인
kubectl describe pod <pod-name>  # 상세 보기
kubectl logs <pod-name>          # 컨테이너 로그 보기

# 격리 배포를 위한 네임스페이스 생성
kubectl create ns sfms-dev
kubectl apply -n sfms-dev -f app.yaml
```

### 8.2 데몬 관리 및 제거

```bash
sudo systemctl restart k3s
sudo journalctl -u k3s -f        # 데몬 단위 에러 실시간 조회

# k3s 완전 제거 (클러스터 데이터 전체 삭제)
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## 9. Podman 5.x + k3s 조합 파이프라인 요약

1. **개발 및 빌드 (Rootless Podman):**
안전한 Rootless 환경에서 `pasta` 네트워크를 통해 컨테이너를 빌드하고 로컬 레지스트리로 푸시합니다.

```bash
podman build -t registry.local:5000/sfms-app:v1 .
podman push registry.local:5000/sfms-app:v1
```

1. **배포 및 스케일링 (k3s):**
k3s를 통해 PostgreSQL(PVC/Secret 활용) 데이터베이스와 Nginx 기반 애플리케이션을 안정적으로 운영하며, 무중단 롤링 업데이트를 수행합니다.

```bash
kubectl set image deployment/sfms-app sfms-app=registry.local:5000/sfms-app:v2
```

---
