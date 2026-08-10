# Security

This project integrates security controls throughout the CI/CD and Kubernetes deployment workflow.

## Security Controls

### SonarQube

SonarQube is used for static code analysis and Quality Gate enforcement.

The CI pipeline runs SonarQube analysis for the `develop` branch and Pull Requests.

The pipeline uses Jenkins-managed credentials for authentication:

```text
Jenkins Credentials
        ↓
   SonarQube Token
        ↓
SonarQube Analysis
        ↓
   Quality Gate
```

A failed Quality Gate prevents the pipeline from continuing.

### Trivy Filesystem and Dependency Scanning

Trivy is used during the CI process to scan the project filesystem and dependencies for known vulnerabilities.

The scan is configured to identify security vulnerabilities before artifacts are published.

### Trivy Container Image Scanning

Trivy is also used to scan Docker container images.

The CD pipeline scans the image for `HIGH` and `CRITICAL` vulnerabilities:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --no-progress \
  <image>:<tag>
```

The `--exit-code 1` configuration causes the pipeline stage to fail when vulnerabilities meeting the configured severity threshold are detected.

The same security validation is performed before Kubernetes deployment.

## Jenkins Credentials

Sensitive CI/CD credentials are managed through Jenkins Credentials rather than being stored directly in the repository.

Examples include:

* SonarQube token
* Nexus credentials
* Docker Hub credentials

The Jenkins pipelines retrieve these credentials at runtime using Jenkins credential bindings.

Example:

```groovy
withCredentials([
    usernamePassword(
        credentialsId: 'nexus-creds',
        usernameVariable: 'NEXUS_USER',
        passwordVariable: 'NEXUS_PASS'
    )
]) {
    // deployment or artifact operation
}
```

This keeps credentials outside the Git repository.

## Kubernetes Secrets

Sensitive application configuration is provided to Kubernetes through Secrets.

The application deployment references the Kubernetes Secret instead of embedding sensitive configuration directly into the Deployment configuration.

Example:

```yaml
envFrom:
  - configMapRef:
      name: petclinic-config
  - secretRef:
      name: petclinic-secret
```

Kubernetes Secrets are therefore used for sensitive application configuration.

## No Hardcoded Credentials

Application and CI/CD credentials should not be committed directly into source-controlled configuration.

The implemented workflow separates credentials from the application source code by using:

```text
Jenkins
   ↓
Jenkins Credentials
   ↓
CI/CD Pipelines

Kubernetes
   ↓
Kubernetes Secrets
   ↓
Application Pods
```

## Security Flow

The overall security flow is:

```text
Developer
    ↓
GitHub
    ↓
Jenkins CI
    ↓
┌─────────────────────────────┐
│ SonarQube                   │
│ Quality Gate                │
│ Trivy Filesystem Scan       │
└─────────────────────────────┘
    ↓
Build Artifact
    ↓
Nexus
    ↓
Docker Image
    ↓
Trivy Container Image Scan
    ↓
Jenkins CD
    ↓
Kubernetes
    ↓
Kubernetes Secrets
```

These controls provide code-quality analysis, vulnerability scanning, credential protection, and secure application configuration across the DevOps workflow.
