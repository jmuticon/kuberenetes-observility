#!/usr/bin/env bash

set -e

ROOT_DIR=$(pwd)

echo "Ensure minikube is running..."
minikube status || (minikube start --memory=3072 --cpus=2)

minikube addons enable ingress

kubectl create ns observability || true
kubectl create ns app || true

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install observability prometheus-community/kube-prometheus-stack \
  -n observability -f ./k8s/observability/prometheus-stack-values.yaml

kubectl apply -n observability -f ./k8s/observability/loki.yaml
kubectl apply -n observability -f ./k8s/observability/promtail.yaml
kubectl apply -n observability -f ./k8s/observability/tempo.yaml
kubectl apply -n observability -f ./k8s/observability/otel-collector.yaml
kubectl apply -n observability -f ./k8s/observability/prometheus-rules.yaml
kubectl apply -n observability -f ./k8s/observability/alertmanager-config.yaml
kubectl apply -n observability -f ./k8s/observability/grafana-datasources.yaml
kubectl apply -n observability -f ./k8s/observability/grafana-dashboard-nodejs.json
kubectl apply -n observability -f ./k8s/observability/grafana-dashboard-mysql.json
kubectl apply -n observability -f ./k8s/observability/grafana-ingress.yaml

kubectl apply -n app -f ./k8s/app/backend-deployment.yaml
kubectl apply -n app -f ./k8s/app/backend-service.yaml
kubectl apply -n app -f ./k8s/app/frontend-deployment.yaml
kubectl apply -n app -f ./k8s/app/frontend-service.yaml
kubectl apply -n app -f ./k8s/app/ingress.yaml
kubectl apply -n app -f ./k8s/app/mysql-deployment.yaml
kubectl apply -n app -f ./k8s/app/mysql-service.yaml
kubectl apply -n app -f ./k8s/app/mysql-exporter-deployment.yaml

kubectl apply -n observability -f ./k8s/app/backend-servicemonitor.yaml

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n app --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=mysql -n app --timeout=300s || true

kubectl get pods -A

echo "Add to /etc/hosts: 127.0.0.1 frontend.local api.local grafana.local"
echo "Done. Open http://frontend.local and http://grafana.local"

