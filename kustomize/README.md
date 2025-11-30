# Trilium Kustomize

이 디렉토리는 Trilium Helm Chart를 Kustomize로 변환한 구조입니다.

## 구조

```
kustomize/
├── base/                          # 공통 리소스
│   ├── configmap.yaml            # Trilium ConfigMap
│   ├── service.yaml              # Trilium Service
│   ├── deployment.yaml           # Trilium Deployment (기본 replicas=1)
│   └── kustomization.yaml
└── overlays/                      # 환경별 오버레이
    ├── dev/                      # 개발 환경
    │   ├── kustomization.yaml
    │   ├── pv.yaml               # NFS PersistentVolume (20Gi)
    │   ├── pvc.yaml              # PersistentVolumeClaim
    │   ├── gateway.yaml          # Istio IngressGateway Gateway
    │   ├── virtualservice.yaml   # Istio VirtualService (트래픽 라우팅)
    │   ├── telemetry.yaml        # Istio Telemetry (로그 수집)
    │   └── deployment-patch.yaml
    └── prod/                     # 프로덕션 환경
        ├── kustomization.yaml
        ├── pv.yaml               # NFS PersistentVolume (64Gi)
        ├── pvc.yaml              # PersistentVolumeClaim
        ├── gateway.yaml          # Istio IngressGateway Gateway
        ├── virtualservice.yaml   # Istio VirtualService (트래픽 라우팅)
        ├── telemetry.yaml        # Istio Telemetry (로그 수집)
        └── deployment-patch.yaml # replicas=2 패치
```

## 사용 방법

### 개발 환경 배포

```bash
kubectl apply -k kustomize/overlays/dev
```

### 프로덕션 환경 배포

```bash
kubectl apply -k kustomize/overlays/prod
```

### 빌드 결과 확인 (미리보기)

```bash
# 개발 환경
kubectl kustomize kustomize/overlays/dev

# 프로덕션 환경
kubectl kustomize kustomize/overlays/prod
```

## 주요 차이점

### dev vs prod

- **replicas**: dev는 1, prod는 2
- **PV/PVC 크기**: dev는 20Gi, prod는 64Gi
- **accessModes**: dev는 ReadWriteOnce, prod는 ReadWriteMany
- **namespace**: prod의 PVC만 namespace: trilium 설정

## Istio IngressGateway

dev와 prod 환경 모두 Istio IngressGateway를 통해 트래픽을 라우팅합니다.

### 설정된 리소스

- **Gateway**: Istio IngressGateway를 사용하는 Gateway 리소스
  - HTTP 포트 80에서 모든 호스트의 트래픽 수신
- **VirtualService**: 트래픽을 Trilium 서비스로 라우팅
  - 모든 경로(`/`)를 Trilium 서비스의 8080 포트로 전달
- **Telemetry**: 로그 수집, 메트릭, 트레이싱 설정
  - Access Logging (Envoy)
  - Metrics (Prometheus)
  - Tracing (Zipkin)

### IngressGateway 확인

```bash
# IngressGateway pod 확인
kubectl get pods -n istio-system -l istio=ingressgateway

# Gateway 상태 확인
kubectl get gateway -n trilium

# VirtualService 확인
kubectl get virtualservice -n trilium

# Telemetry 설정 확인
kubectl get telemetry -n trilium
```

### 트래픽 접근

IngressGateway의 외부 IP를 확인하여 Trilium에 접근할 수 있습니다:

```bash
# IngressGateway의 외부 IP 확인
kubectl get svc -n istio-system istio-ingressgateway

# 접근 예시
curl http://<EXTERNAL-IP>/
```

### 로그 확인

IngressGateway는 Envoy access log를 수집합니다. 로그를 확인하려면:

```bash
# IngressGateway pod의 로그 확인
kubectl logs -n istio-system -l istio=ingressgateway -f
```

## 참고

- `charts/trilium/dev/dev.yaml`과 `charts/trilium/prod/prod.yaml`은 Helm Chart에서 렌더링된 결과입니다.
- Kustomize 빌드 결과에는 PV/PVC가 포함되어 있으며, 이는 배포에 필요한 리소스입니다.
- Kustomize는 리소스를 알파벳 순으로 정렬하므로, Helm Chart 렌더링 결과와 리소스 순서가 다를 수 있습니다.
- Istio Ambient Mesh가 클러스터에 설치되어 있어야 waypoint proxy가 정상 동작합니다.
