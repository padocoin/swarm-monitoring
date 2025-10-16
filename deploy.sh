#!/bin/bash

# =====================================
# PadoCoin Swarm Monitoring Deployment
# Manager: 192.168.0.3
# Workers: 192.168.0.4, 192.168.0.5, 192.168.0.6
# =====================================

# 서비스 이름
STACK_NAME="pado_monitoring"

# 워커 노드 리스트
WORKERS=("192.168.0.4" "192.168.0.5" "192.168.0.6")

echo "🚀 [1/5] Git 업데이트 중..."
git pull origin main || { echo "❌ Git pull 실패"; exit 1; }

echo "🐳 [2/5] Docker 이미지 빌드 중..."
docker build -t padocoin/monitoring:latest . || { echo "❌ 이미지 빌드 실패"; exit 1; }

echo "📦 [3/5] 이미지 워커 노드로 전송 중..."
for worker in "${WORKERS[@]}"; do
  echo "➡️ 전송: $worker"
  docker save padocoin/monitoring:latest | ssh root@$worker "docker load"
done

echo "🧩 [4/5] Stack 배포 중..."
docker stack deploy -c docker-compose.yml $STACK_NAME || { echo "❌ 스택 배포 실패"; exit 1; }

echo "✅ [5/5] 배포 완료!"
docker stack services $STACK_NAME
