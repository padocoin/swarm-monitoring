#!/bin/bash
set -e

echo "🚀 PadoCoin Swarm Monitoring Full Deployment 시작..."
echo "현재 노드: $(hostname)"

# ===============================
# 1. 디렉토리 준비
# ===============================
mkdir -p prometheus

# ===============================
# 2. Prometheus 설정 파일 생성
# ===============================
cat > prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets:
          - '192.168.0.3:9100'
          - '192.168.0.4:9100'
          - '192.168.0.5:9100'
          - '192.168.0.6:9100'
EOF

# ===============================
# 3. docker-compose.yml 생성
# ===============================
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - monitoring
    deploy:
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    networks:
      - monitoring
    environment:
      GF_SECURITY_ADMIN_USER: "admin"
      GF_SECURITY_ADMIN_PASSWORD: "admin"
    deploy:
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    networks:
      - monitoring
    deploy:
      mode: global
      restart_policy:
        condition: on-failure

networks:
  monitoring:
    driver: overlay
EOF

# ===============================
# 4. Git 업데이트
# ===============================
if [ -d ".git" ]; then
    echo "📦 Git pull 최신화"
    git pull origin main || echo "⚠️ Git pull 실패, 계속 진행"
fi

# ===============================
# 5. Docker Stack 배포
# ===============================
echo "🧩 Docker Stack 배포 중..."
docker stack deploy -c docker-compose.yml swarm-monitoring

# ===============================
# 6. 배포 완료 메시지
# ===============================
echo ""
echo "✅ 배포 완료!"
echo "--------------------------------------------------"
echo "🌐 Grafana     : http://192.168.0.3:3000 (admin / admin)"
echo "📊 Prometheus  : http://192.168.0.3:9090"
echo "--------------------------------------------------"
echo "💡 모든 워커 노드의 Node Exporter도 자동 배포 완료!"
