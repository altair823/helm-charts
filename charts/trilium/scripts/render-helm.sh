#!/bin/bash

# Helm chart를 렌더링하여 Kustomize base에 저장하는 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$CHART_DIR/kustomize/base"
RENDERED_DIR="$BASE_DIR/rendered"
RELEASE_NAME="${RELEASE_NAME:-trilium}"
NAMESPACE="${NAMESPACE:-default}"

# values 파일 선택 (첫 번째 인자 또는 기본값)
if [ -n "$1" ]; then
    VALUES_FILE="$1"
else
    VALUES_FILE="${VALUES_FILE:-$CHART_DIR/values.yaml}"
fi

if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: Values file not found: $VALUES_FILE"
    exit 1
fi

echo "=========================================="
echo "Helm Chart 렌더링"
echo "=========================================="
echo "Chart directory: $CHART_DIR"
echo "Base directory: $BASE_DIR"
echo "Release name: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Values file: $VALUES_FILE"
echo ""

# Helm dependencies 업데이트
echo "Updating Helm dependencies..."
cd "$CHART_DIR"
helm dependency update

# 기존 렌더링 결과 삭제
if [ -d "$RENDERED_DIR" ]; then
    echo "Cleaning up old rendered files..."
    rm -rf "$RENDERED_DIR"
fi

# Helm template 렌더링
echo "Rendering Helm template..."
helm template "$RELEASE_NAME" . \
  --namespace "$NAMESPACE" \
  --values "$VALUES_FILE" \
  --output-dir "$RENDERED_DIR"

# 렌더링 완료 마커 생성
touch "$RENDERED_DIR/.rendered"

echo ""
echo "✅ Helm chart가 성공적으로 렌더링되었습니다."
echo "렌더링된 파일: $RENDERED_DIR"
echo ""

# kustomization.yaml 자동 업데이트 시도
KUSTOMIZATION_FILE="$BASE_DIR/kustomization.yaml"
if [ -f "$KUSTOMIZATION_FILE" ]; then
    # 렌더링된 파일 찾기
    RENDERED_FILES=$(find "$RENDERED_DIR" -name "*.yaml" -type f | sed "s|$BASE_DIR/||" | sort)
    
    if [ -n "$RENDERED_FILES" ]; then
        echo "렌더링된 파일 목록:"
        echo "$RENDERED_FILES" | sed 's/^/  - /'
        echo ""
        echo "💡 kustomize/base/kustomization.yaml 파일의 resources 섹션에 위 파일들을 추가하세요."
    fi
fi

