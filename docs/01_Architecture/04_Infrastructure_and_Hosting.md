# 04. Infrastructure and Hosting

## 1. The Philosophy: Secure, Automated, and Observable

Our infrastructure is not just a place to run our code; it is a core part of our product. It is designed to be:

*   **Secure:** We operate on a principle of least privilege. All access is controlled, authenticated, and audited.
*   **Automated:** Our entire infrastructure is defined as code (IaC) using Terraform. This eliminates manual configuration errors and makes our infrastructure repeatable and auditable.
*   **Observable:** We have deep visibility into the health and performance of our system through comprehensive logging, monitoring, and tracing.

## 2. The GCP Blueprint

### 2.1. Project and Network

*   **Project Structure:** A dedicated GCP project per environment (`dev`, `staging`, `prod`). This provides strong isolation.
*   **VPC:** A shared VPC architecture will be used. The `prod` project will host the VPC, and the `dev` and `staging` projects will be service projects that use the same VPC.
*   **Subnets:** Private subnets in multiple regions for high availability.
*   **Security:**
    *   **Cloud Armor:** To protect against DDoS attacks and other web-based threats.
    *   **VPC Service Controls:** To create a service perimeter that prevents data exfiltration.

### 2.2. Compute (GKE)

*   **Clusters:** A GKE cluster per environment.
*   **Node Pools:** Multiple node pools with auto-scaling enabled:
    *   `default-pool`: For general-purpose workloads.
    *   `high-cpu-pool`: For CPU-intensive services like FastAPI.
    *   `high-memory-pool`: For memory-intensive services.
*   **Security:**
    *   **Workload Identity:** To provide GKE pods with secure access to other GCP services.
    *   **GKE Sandbox:** To run untrusted or third-party code in a sandboxed environment.

### 2.3. Data Tier

*   **Databases:** Cloud SQL for PostgreSQL, with HA replicas and automated backups.
*   **Storage:** Google Cloud Storage for object storage, with lifecycle policies to move old data to cheaper storage classes.
*   **Caching:** Memorystore for Redis for caching frequently accessed data (e.g., the shard mapping).

### 2.4. API Management and Messaging

*   **API Gateway:** Apigee X for managing all external API traffic.
*   **Messaging:** Google Pub/Sub for asynchronous, event-driven communication.

## 3. The Terraform Workflow

1.  **Branching:** All Terraform code is managed in a separate Git repository. We use a `develop` and `main` branch strategy.
2.  **Pull Request:** A developer makes a change to the Terraform code and creates a PR.
3.  **CI/CD for Infra:** The CI/CD pipeline will:
    a.  Run `terraform fmt` and `terraform validate`.
    b.  Run `terraform plan` to generate a plan of the changes.
    c.  Post the plan as a comment on the PR for review.
4.  **Apply:** Once the PR is approved, the changes are applied to the appropriate environment.

## 4. Observability

*   **Logging:** Structured JSON logs to Google Cloud Logging.
*   **Monitoring:** Google Cloud Monitoring with custom dashboards and alerting policies.
*   **Tracing:** Google Cloud Trace for end-to-end request tracing.
*   **Error Reporting:** Google Cloud Error Reporting to automatically capture and report application errors.
