#!/bin/bash

# Kustomize를 사용하여 Helm chart를 적용하는 통합 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
OVERLAY="${1:-prod}"  # 기본값: prod

if [ ! -d "$CHART_DIR/kustomize/overlays/$OVERLAY" ]; then
    echo "Error: Overlay '$OVERLAY' not found"
    echo "Available overlays:"
    ls -1 "$CHART_DIR/kustomize/overlays/" 2>/dev/null || echo "  (none)"
    exit 1
fi

OVERLAY_DIR="$CHART_DIR/kustomize/overlays/$OVERLAY"

echo "=========================================="
echo "Kustomize를 사용한 Trilium 배포"
echo "=========================================="
echo "Overlay: $OVERLAY"
echo "Directory: $OVERLAY_DIR"
echo ""

# Helm chart 렌더링 (base가 비어있는 경우)
RENDERED_MARKER="$CHART_DIR/kustomize/base/rendered/.rendered"
VALUES_FILE="$CHART_DIR/$OVERLAY/values.yaml"
if [ ! -f "$VALUES_FILE" ]; then
    VALUES_FILE="$CHART_DIR/values.yaml"
fi

if [ ! -f "$RENDERED_MARKER" ] || [ "$VALUES_FILE" -nt "$RENDERED_MARKER" ]; then
    echo "Helm chart를 렌더링합니다..."
    "$SCRIPT_DIR/render-helm.sh" "$VALUES_FILE"
    echo ""
fi

# Kustomize 빌드 (미리보기)
echo "Kustomize 빌드 미리보기:"
echo "----------------------------------------"
kubectl kustomize "$OVERLAY_DIR"
echo ""
echo "----------------------------------------"

# 적용 확인
read -p "위 설정을 적용하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 0
fi

# 적용
echo "Kubernetes에 적용 중..."
kubectl apply -k "$OVERLAY_DIR"

echo ""
echo "배포가 완료되었습니다!"
echo ""
echo "상태 확인:"
echo "  kubectl get pods -l app.kubernetes.io/name=trilium"
echo "  kubectl get deployment trilium"

