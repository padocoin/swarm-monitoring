#!/bin/bash
set -e

echo "=== Swarm Monitoring Full Auto Deployment ==="

read -p "매니저 노드 IP/호스트명: " MANAGER
read -p "워커 노드 1 IP/호스트명: " WORKER1
read -p "워커 노드 2 IP/호스트명: " WORKER2
read -p "워커 노드 3 IP/호스트명: " WORKER3

NODES=("$MANAGER" "$WORKER1" "$WORKER2" "$WORKER3")

TARGETS=""
for NODE in "${NODES[@]}"; do
  TARGETS="$TARGETS'$NODE:9323',"
done
TARGETS=${TARGETS%,}

cat > prometheus/prometheus.yml <<EOL
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: [$TARGETS]
EOL

echo "✅ prometheus.yml 업데이트 완료"

docker stack deploy -c docker-compose.yml monitoring
echo "✅ Swarm Monitoring Stack 배포 완료"

echo "Prometheus: http://$MANAGER:9090"
echo "Grafana: http://$MANAGER:3000 (ID/Password: admin/admin)"
