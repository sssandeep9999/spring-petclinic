# Project Documentation

This directory contains documentation for the Spring PetClinic DevOps implementation.

## Documentation Structure

```text
docs/
├── architecture/
│   └── architecture.mmd
│
├── images/
│   └── spring-petclinic-devops-architecture.png
│
├── spring-petclinic-devops-architecture.drawio
│
└── README.md
```

## Architecture

### Spring PetClinic DevOps Architecture

The architecture diagram represents the end-to-end DevOps implementation covering source control, continuous integration, security scanning, artifact management, containerization, continuous delivery, Kubernetes deployment, and monitoring.

![Spring PetClinic DevOps Architecture](images/spring-petclinic-devops-architecture.png)

[View editable architecture diagram](spring-petclinic-devops-architecture.drawio)

## DevOps Components

| Component | Purpose |
|---|---|
| GitHub | Source code management and branch-based development |
| Jenkins | Continuous Integration and Continuous Delivery |
| Maven | Application build and test automation |
| SonarQube | Static code analysis and Quality Gate |
| Trivy | Container image security scanning |
| Nexus Repository | Artifact repository |
| Docker | Container image creation |
| Docker Hub | Container image registry |
| Kubernetes / k3d | Application deployment and orchestration |
| ConfigMap | Kubernetes application configuration |
| Secret | Kubernetes sensitive configuration |
| HPA | Kubernetes horizontal pod autoscaling |
| NodePort | Application service exposure |
| Prometheus | Metrics collection |
| Grafana | Monitoring and visualization |

## Documentation

The documentation in this directory will contain the architecture diagrams and supporting DevOps implementation documentation as the project documentation is expanded.

---

Editable diagrams are maintained in `.drawio` format and exported as PNG images for documentation.
