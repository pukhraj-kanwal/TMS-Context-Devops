# 16. Infrastructure Runbooks

## 1. Purpose and Scope

This document provides step-by-step operational procedures for common infrastructure tasks. These runbooks ensure consistent, reliable operations across all environments.

## 2. Emergency Response Procedures

### 2.1. Service Outage Response

**Priority 1: Complete Service Outage**
1. Acknowledge the incident in monitoring system
2. Check GCP status page for platform-wide issues
3. Verify GKE cluster health: `kubectl get nodes`
4. Check ingress controller status: `kubectl get pods -n ingress-nginx`
5. Review application pod status: `kubectl get pods --all-namespaces`
6. If infrastructure issue: Execute rollback procedures (Section 3.2)
7. If application issue: Contact development team lead

**Priority 2: Degraded Performance**
1. Check CPU/Memory utilization in Cloud Monitoring
2. Review Cloud SQL performance metrics
3. Verify Redis cache hit rates
4. Scale up affected node pools if needed
5. Check Pub/Sub message backlog

### 2.2. Database Emergency Procedures

**High Connection Count:**
```bash
# Check current connections
gcloud sql operations list --instance=gemini-tms-prod-db

# Enable read replicas if needed
gcloud sql instances patch gemini-tms-prod-db --replica-names=read-replica-1
```

**Storage Full:**
```bash
# Increase storage (cannot be decreased)
gcloud sql instances patch gemini-tms-prod-db --storage-size=500GB
```

## 3. Deployment Procedures

### 3.1. Standard Deployment

**Staging Deployment (Automatic on develop merge):**
1. CI/CD pipeline triggers automatically
2. Monitor deployment in GitHub Actions
3. Verify staging health checks pass
4. Run smoke tests against staging environment

**Production Deployment (Manual approval required):**
1. Create release branch: `git checkout -b release/v1.2.3`
2. Update version numbers and changelog
3. Trigger production deployment workflow
4. Approve deployment in GitHub Actions
5. Monitor production metrics for 30 minutes post-deployment

### 3.2. Emergency Rollback Procedures

**Application Rollback:**
```bash
# Rollback to previous Helm release
helm rollback gemini-tms-prod 1

# Verify rollback success
kubectl get pods -l app=gemini-tms
kubectl logs -l app=gemini-tms --tail=100
```

**Infrastructure Rollback:**
```bash
# Revert Terraform changes
cd terraform/
terraform workspace select prod
terraform plan -destroy -target=resource.name
terraform apply -target=resource.name
```

## 4. Maintenance Procedures

### 4.1. GKE Cluster Maintenance

**Node Pool Upgrades:**
```bash
# Upgrade cluster control plane first
gcloud container clusters upgrade gemini-tms-prod --master

# Upgrade node pools (rolling update)
gcloud container node-pools upgrade default-pool --cluster=gemini-tms-prod
```

**Certificate Renewal:**
```bash
# Let's Encrypt certificates auto-renew via cert-manager
# Manual check:
kubectl get certificates -A
kubectl describe certificate tls-secret -n default
```

### 4.2. Database Maintenance

**Automated Backups Verification:**
```bash
# Verify backup schedule
gcloud sql backups list --instance=gemini-tms-prod-db

# Test backup restoration (staging)
gcloud sql backups restore BACKUP_ID --restore-instance=gemini-tms-staging-db
```

## 5. Monitoring and Health Checks

### 5.1. Critical Metrics to Monitor

- **Application Health:** HTTP 200 response rate > 99.5%
- **Database Performance:** Query response time < 100ms average
- **Cache Hit Rate:** Redis hit rate > 90%
- **Resource Utilization:** CPU < 70%, Memory < 80%
- **Error Rates:** Application error rate < 0.1%

### 5.2. Health Check Commands

```bash
# Application health
curl -f https://api.gemini-tms.com/health

# Database connectivity
kubectl exec -it db-client -- psql -h $DB_HOST -U $DB_USER -c "SELECT 1;"

# Redis connectivity
kubectl exec -it redis-client -- redis-cli ping

# Pub/Sub status
gcloud pubsub topics list
gcloud pubsub subscriptions list
```

## 6. Security Incident Response

### 6.1. Suspected Breach

1. **Immediate Actions:**
   - Isolate affected systems
   - Preserve logs and evidence
   - Change all service account keys
   - Enable additional monitoring

2. **Investigation:**
   - Review audit logs in Cloud Logging
   - Check for unauthorized API calls
   - Verify IAM policy changes
   - Scan for malicious containers

3. **Recovery:**
   - Rotate all secrets in Secret Manager
   - Update firewall rules if needed
   - Apply security patches
   - Document lessons learned

### 6.2. Security Commands

```bash
# Review audit logs
gcloud logging read "protoPayload.authenticationInfo.principalEmail!=\"service-account@gemini-tms.iam.gserviceaccount.com\"" --limit=100

# Check IAM policy changes
gcloud projects get-iam-policy cargolynx-main

# Rotate service account keys
gcloud iam service-accounts keys create new-key.json --iam-account=terraform@cargolynx-main.iam.gserviceaccount.com
```

## 7. Cost Management

### 7.1. Weekly Cost Review

```bash
# Check current month spending
gcloud billing accounts list
gcloud beta billing budgets list --billing-account=BILLING_ACCOUNT_ID

# Review resource usage
gcloud compute instances list --format="table(name,machineType,status,zone)"
gcloud sql instances list --format="table(name,tier,region,status)"
```

### 7.2. Cost Optimization Actions

- **Right-size GKE nodes:** Use cluster autoscaler and VPA
- **Optimize Cloud SQL:** Use read replicas and connection pooling
- **Storage lifecycle:** Implement Cloud Storage lifecycle policies
- **Resource cleanup:** Regular cleanup of unused resources