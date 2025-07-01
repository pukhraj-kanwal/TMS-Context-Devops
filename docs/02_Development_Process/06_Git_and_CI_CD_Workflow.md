# 06. Git and CI/CD Workflow

## 1. The Philosophy: Automation and Control

This document is the single source of truth for our branching strategy and CI/CD pipeline. The goal is to create a fully automated, secure, and reliable path from a developer's local machine to the production environment.

## 2. The Git Branching Model

We use a strict, release-focused branching model.

*   **`main`**: Represents the production state. Only `release/` and `hotfix/` branches can be merged into `main`.
*   **`develop`**: The integration branch for the next release. All `feature/` branches are merged into `develop`.
*   **`feature/<service-name>/<jira-ticket>-<description>`**: For all new features and non-critical bug fixes.
*   **`release/vX.Y.Z`**: For preparing a production release.
*   **`hotfix/vX.Y.Z`**: For urgent production bugs.

## 3. The CI/CD Pipeline (GitHub Actions)

### 3.1. The CI Pipeline (On PR to `develop`)

*   **Trigger:** `on: pull_request` (to `develop`)
*   **Jobs:**
    1.  **`lint-and-test`**: Runs linting, static analysis, unit tests, and integration tests for all changed services.
    2.  **`security-scan`**: Scans for vulnerable dependencies and code vulnerabilities.
    3.  **`build-docker`**: Builds a Docker image for each changed service.

### 3.2. The CD Pipeline (On Merge to `develop` -> Staging)

*   **Trigger:** `on: push` (to `develop`)
*   **Jobs:**
    1.  **`push-docker`**: Pushes the Docker images to Google Container Registry.
    2.  **`deploy-to-staging`**: Deploys the new images to the `staging` GKE cluster using Helm.

### 3.3. The Release Pipeline (On `release/*` -> Production)

*   **Trigger:** `on: workflow_dispatch` (on `release/*` branch)
*   **Jobs:**
    1.  **`deploy-to-production`**: Deploys the images to the `production` GKE cluster. This job requires manual approval.
    2.  **`tag-release`**: Creates a Git tag for the release.
    3.  **`merge-and-cleanup`**: Merges the release branch into `main` and `develop`.

## 4. Versioning Strategy

We use Semantic Versioning (SemVer) `vX.Y.Z`.

*   **`X` (Major):** For breaking changes.
*   **`Y` (Minor):** For new features.
*   **`Z` (Patch):** For bug fixes.

## 5. Risks and Mitigation

*   **Pipeline Flakiness:** The CI/CD pipeline may fail for reasons unrelated to the code change.
    *   **Mitigation:** We will have a dedicated on-call engineer responsible for maintaining the health of the pipeline.
*   **Long-Lived Feature Branches:** Feature branches that are not merged for a long time can be difficult to integrate.
    *   **Mitigation:** We will encourage developers to break down large features into smaller, more manageable chunks.
