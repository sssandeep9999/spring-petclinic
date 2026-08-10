# Monitoring and Observability

This project uses a Kubernetes monitoring stack to observe cluster, node, and pod metrics and provide alerting capabilities.

## Monitoring Stack

The monitoring stack is installed using Helm and the `kube-prometheus-stack` chart.

### Components

* **Prometheus** — collects metrics
* **Grafana** — visualizes metrics through dashboards
* **Alertmanager** — handles alerts and notifications
* Kubernetes and node metrics are also included in the monitoring stack.

## Helm Installation

Helm is used as the Kubernetes package manager for installing the monitoring stack.

The Prometheus Community Helm repository is used:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Create the monitoring namespace:

```bash
kubectl create namespace monitoring
```

Install the monitoring stack:

```bash
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
```

### Verify Monitoring Components

```bash
kubectl get pods -n monitoring
```

The monitoring namespace should contain running Prometheus, Grafana, and Alertmanager components.

## Grafana

Grafana is used to visualize the metrics collected by Prometheus.

Access Grafana using port forwarding:

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

Open:

```text
http://localhost:3000
```

The dashboards provide visibility into:

* CPU usage
* Memory usage
* Pod count
* Node status
* Kubernetes cluster metrics

## Alertmanager

Alertmanager handles notifications after Prometheus detects an alert condition.

Access Alertmanager using:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring
```

Open:

```text
http://localhost:9093
```

The alert flow is:

```text
Application / Kubernetes
        ↓
     Metrics
        ↓
    Prometheus
        ↓
    Alert Rules
        ↓
   Alert Triggered
        ↓
   Alertmanager
        ↓
 Email / Slack / Teams / PagerDuty
```

Prometheus detects the alert condition based on an alert rule, while Alertmanager handles the notification.

## Prometheus Alert Rule

A custom `PrometheusRule` can be used to detect when a pod is not ready.

Example alert:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-pod-alerts
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
    - name: kubernetes-alerts
      rules:
        - alert: PodNotReady
          expr: kube_pod_status_ready{condition="false"} == 1
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: "Pod is not ready"
            description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been not ready for more than 2 minutes."
```

Apply the rule:

```bash
kubectl apply -f pod-alert.yaml
```

Verify:

```bash
kubectl get prometheusrules -n monitoring
```

## Alert Verification

Prometheus can be accessed using:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
```

Open:

```text
http://localhost:9090
```

Under **Alerts**, the `PodNotReady` alert can be observed through these states:

```text
INACTIVE
   ↓
PENDING
   ↓
FIRING
```

The alert remains pending according to the configured `for: 2m` duration before firing.

## Alert Notifications

Alertmanager can be configured with notification receivers such as email.

In a production environment, SMTP credentials or other sensitive notification credentials should not be stored directly in Git-managed configuration files.

The documented secret-management flow is:

```text
AWS Secrets Manager
        ↓
Kubernetes Secret
        ↓
Alertmanager
```

## Alert Recovery

After the condition causing the alert is fixed, the alert should recover:

```text
FIRING
   ↓
RESOLVED
```

Alertmanager can also send a resolved notification.

## Observability Flow

The overall monitoring architecture is:

```text
Kubernetes / Application
          ↓
       Metrics
          ↓
      Prometheus
          ↓
   ┌──────┴──────┐
   ↓             ↓
Grafana      Alert Rules
   ↓             ↓
Dashboards   Alertmanager
                 ↓
            Notifications
```

This provides monitoring, visualization, alerting, and alert recovery for the Kubernetes environment.
