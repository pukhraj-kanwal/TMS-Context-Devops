# 17. Disaster Recovery Plan

## 1. Executive Summary

This document outlines the disaster recovery (DR) procedures for the Gemini TMS platform. Our DR strategy is designed to ensure business continuity with a Recovery Time Objective (RTO) of 4 hours and Recovery Point Objective (RPO) of 15 minutes.

## 2. Disaster Scenarios and Impact Assessment

### 2.1. Scenario Classification

**Level 1: Single Component Failure**
- Impact: Degraded performance, some features unavailable
- Examples: Single microservice crash, single database replica failure
- RTO: 30 minutes, RPO: 5 minutes

**Level 2: Regional Service Outage**
- Impact: Complete service unavailability in primary region
- Examples: GCP region outage, major network partition
- RTO: 2 hours, RPO: 15 minutes

**Level 3: Complete Data Center Failure**
- Impact: All primary infrastructure destroyed
- Examples: Natural disaster, complete GCP project compromise
- RTO: 4 hours, RPO: 30 minutes

### 2.2. Business Impact Analysis

| Service Component | Criticality | Max Downtime | Impact |
|------------------|-------------|--------------|---------| 
| Company Management API | Critical | 1 hour | Customer operations stop |
| Driver Management API | Critical | 1 hour | Fleet operations stop |
| Dispatch Service | Critical | 30 minutes | No new load assignments |
| Asset Management | High | 2 hours | Reduced visibility |
| Notification Service | Medium | 4 hours | Communication delays |

## 3. Recovery Procedures

### 3.1. Level 1: Component Recovery

**Automatic Recovery (Handled by Platform):**
- Pod restarts via Kubernetes liveness probes
- Database failover to read replicas
- Load balancer health checks route around failed instances
- Horizontal Pod Autoscaler scales up healthy pods

**Manual Intervention Steps:**
```bash
# 1. Identify failed component
kubectl get pods --all-namespaces | grep -v Running

# 2. Check recent events
kubectl describe pod <failing-pod-name>

# 3. Review application logs
kubectl logs <failing-pod-name> --previous

# 4. Force restart if needed
kubectl delete pod <failing-pod-name>

# 5. Scale up if persistent issues
kubectl scale deployment <deployment-name> --replicas=3
```

### 3.2. Level 2: Regional Failover

**Prerequisites:**
- Multi-region GKE clusters deployed
- Cross-region database replicas configured
- DNS failover configured with Cloud DNS

**Recovery Steps:**

1. **Assess Scope of Outage**
   ```bash
   # Check GCP status
   curl -s https://status.cloud.google.com/

   # Verify regional resources
   gcloud compute regions list --filter="name:us-central1"
   ```

2. **Activate Secondary Region**
   ```bash
   # Switch to backup region cluster
   gcloud container clusters get-credentials gemini-tms-backup --region=us-east1

   # Promote read replica to primary
   gcloud sql instances promote-replica gemini-tms-backup-db

   # Update DNS to point to backup region
   gcloud dns record-sets transaction start --zone=gemini-tms-zone
   gcloud dns record-sets transaction replace --zone=gemini-tms-zone \
     --name=api.gemini-tms.com --type=A --ttl=60 \
     --data=BACKUP_REGION_IP
   gcloud dns record-sets transaction execute --zone=gemini-tms-zone
   ```

3. **Verify Service Recovery**
   ```bash
   # Test API endpoints
   curl -f https://api.gemini-tms.com/health

   # Check database connectivity
   kubectl exec -it db-client -- psql -h $BACKUP_DB_HOST -c "SELECT version();"

   # Monitor application metrics
   kubectl top pods
   ```

### 3.3. Level 3: Complete Recovery

**Data Recovery Sources:**
- Cloud SQL automated backups (retained for 30 days)
- Cross-region backup storage
- Infrastructure-as-Code (Terraform) for complete rebuild

**Complete Recovery Process:**

1. **Assess Data Integrity**
   ```bash
   # List available database backups
   gcloud sql backups list --instance=gemini-tms-prod-db

   # Verify backup integrity
   gcloud sql backups describe BACKUP_ID --instance=gemini-tms-prod-db
   ```

2. **Rebuild Infrastructure**
   ```bash
   # Initialize new GCP project if needed
   gcloud projects create gemini-tms-recovery --name="Gemini TMS Recovery"

   # Deploy infrastructure via Terraform
   cd terraform/
   terraform workspace new recovery
   terraform plan -var="project_id=gemini-tms-recovery"
   terraform apply
   ```

3. **Restore Data**
   ```bash
   # Create new database instance
   gcloud sql instances create gemini-tms-recovery-db \
     --tier=db-custom-4-16384 \
     --region=us-central1

   # Restore from backup
   gcloud sql backups restore LATEST_BACKUP_ID \
     --restore-instance=gemini-tms-recovery-db \
     --backup-instance=gemini-tms-prod-db
   ```

4. **Deploy Applications**
   ```bash
   # Deploy via CI/CD pipeline to recovery environment
   # Update DNS to point to recovery environment
   # Verify all services are operational
   ```

## 4. Data Backup Strategy

### 4.1. Automated Backups

**Database Backups:**
- **Frequency:** Every 6 hours
- **Retention:** 30 days
- **Type:** Point-in-time recovery enabled
- **Storage:** Cross-region (us-central1 → us-east1)

**Application Data:**
- **Configuration:** Stored in Git repositories
- **Secrets:** Backed up in Secret Manager with cross-region replication
- **File Storage:** Cloud Storage with versioning and lifecycle policies

### 4.2. Backup Verification

**Weekly Backup Tests:**
```bash
#!/bin/bash
# Backup verification script

# Test database backup restoration
BACKUP_ID=$(gcloud sql backups list --instance=gemini-tms-prod-db --limit=1 --format="value(id)")
gcloud sql instances create test-restore-$(date +%s) \
  --source-backup-id=$BACKUP_ID \
  --source-backup-instance=gemini-tms-prod-db

# Verify data integrity
# Clean up test instance
```

## 5. Communication Plan

### 5.1. Incident Communication

**Internal Escalation:**
1. Platform Guardian (immediate notification)
2. Development Team Lead (within 15 minutes)
3. Product Owner (within 30 minutes)
4. Executive Team (within 1 hour for Level 2+ incidents)

**External Communication:**
- Status page updates every 30 minutes
- Customer email notifications for outages > 1 hour
- Post-incident reports within 48 hours

### 5.2. Communication Templates

**Initial Incident Notification:**
```
INCIDENT: [LEVEL] - [BRIEF DESCRIPTION]
Start Time: [TIMESTAMP]
Impact: [AFFECTED SERVICES]
Current Status: [INVESTIGATING/IDENTIFIED/MONITORING]
Next Update: [TIMESTAMP]
```

**Resolution Notification:**
```
RESOLVED: [INCIDENT TITLE]
Resolution Time: [TIMESTAMP]
Root Cause: [BRIEF EXPLANATION]
Preventive Measures: [ACTIONS TAKEN]
Post-Incident Report: [LINK]
```

## 6. Recovery Testing

### 6.1. Testing Schedule

- **Monthly:** Component failure simulation
- **Quarterly:** Regional failover drill
- **Annually:** Complete disaster recovery test

### 6.2. Test Procedures

**Disaster Recovery Drill Checklist:**
- [ ] Notify all stakeholders of planned drill
- [ ] Document baseline performance metrics
- [ ] Execute failover procedures
- [ ] Measure recovery time and data loss
- [ ] Verify all services operational
- [ ] Document lessons learned
- [ ] Update procedures based on findings

## 7. Continuous Improvement

### 7.1. Post-Incident Reviews

After every Level 2+ incident:
1. Root cause analysis within 48 hours
2. Document timeline and decisions made
3. Identify process improvements
4. Update runbooks and procedures
5. Schedule follow-up actions

### 7.2. Metrics and KPIs

- **Mean Time to Recovery (MTTR):** Target < 2 hours
- **Mean Time to Detection (MTTD):** Target < 5 minutes
- **Recovery Success Rate:** Target > 99%
- **Data Loss:** Target < 15 minutes (RPO compliance)

## 8. Emergency Contacts

**Platform Team:**
- Platform Guardian: [ON-CALL-ROTATION]
- Backup Engineer: [SECONDARY-CONTACT]
- Manager: [ESCALATION-CONTACT]

**External Vendors:**
- GCP Support: [SUPPORT-CASE-LINK]
- DNS Provider: [EMERGENCY-CONTACT]
- Monitoring Service: [SUPPORT-CONTACT]