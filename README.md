# CargoLynx TMS - MVP Deployment (Cost-Optimized)

## Overview
This MVP deployment is specifically configured to minimize GCP costs while providing a functional development environment for the CargoLynx TMS platform.

## Cost Optimizations Applied

### 🚀 **Compute (GKE)**
- **Machine Type**: `e2-micro` (1 vCPU, 1GB RAM) - **FREE TIER eligible**
- **Node Count**: 1 node (vs 2 in production)
- **Zones**: Single zone `us-central1-a` (vs multi-zone)
- **Disk Size**: 10GB (vs 50GB in production)
- **Preemptible Nodes**: Enabled (up to 80% cost savings)
- **Spot Instances**: Enabled for additional savings

### 💾 **Database (Cloud SQL)**
- **Tier**: `db-f1-micro` - **FREE TIER eligible** (shared vCPU, 0.6GB RAM)
- **Disk Size**: 10GB minimum (vs 200GB in production)
- **Availability**: Zonal (vs Regional HA)
- **Max Disk Size**: 50GB (vs 2TB in production)
- **Backups**: Weekly (vs daily), 7-day retention (vs 30-day)

### 🔍 **Monitoring & Observability**
- **Managed Prometheus**: Disabled
- **Workload Metrics**: Disabled
- **Audit Logs**: Disabled
- **VPC Flow Logs**: Disabled
- **Data Loss Prevention**: Disabled

### 🛡️ **Security (Non-Essential Features Disabled)**
- **Binary Authorization**: Disabled
- **Network Policies**: Disabled
- **Shielded Nodes**: Disabled
- **Workload Identity**: Kept for basic security

### 📦 **Storage**
- **Bucket Versioning**: Disabled
- **Lifecycle Management**: Aggressive (7 days vs 30 days)
- **Retention**: 1 year (vs 7 years in production)

### 🌐 **Networking**
- **SSL Certificates**: Disabled (use HTTP for development)
- **CDN**: Disabled
- **Domain**: `dev.cargolynx.com` (vs production domain)

### ⚡ **Performance Features (Disabled for Cost Savings)**
- **Horizontal Pod Autoscaling**: Disabled
- **Vertical Pod Autoscaling**: Disabled
- **Cluster Autoscaling Profiles**: Disabled

## Estimated Monthly Costs

### Free Tier Resources (Always Free)
- **Cloud SQL**: `db-f1-micro` with 30GB storage
- **Compute Engine**: 1 `e2-micro` instance (744 hours/month)
- **Cloud Storage**: 5GB standard storage
- **Cloud Functions**: 2M invocations, 400K GB-seconds

### Estimated Paid Costs (USD/month)
- **GKE Cluster Management**: $74.40/month (standard rate)
- **Additional Storage**: ~$2-5/month (if exceeding free tier)
- **Network Egress**: ~$1-3/month (minimal for development)

**Total Estimated Cost: ~$77-82/month** (vs $300-500/month for production setup)

## GCP Free Tier Eligibility

This configuration maximizes use of GCP's Always Free tier:
- ✅ `e2-micro` instance (1 per project)
- ✅ `db-f1-micro` Cloud SQL instance
- ✅ 5GB Cloud Storage
- ✅ Basic monitoring and logging

## Scaling Path

When ready to scale from MVP to production:
1. Increase machine types (`e2-micro` → `e2-standard-2`)
2. Add multi-zone deployment
3. Enable Regional HA for database
4. Add monitoring and security features
5. Implement proper backup strategy
6. Enable SSL/TLS and CDN

## Important Notes

⚠️ **Development Only**: This configuration is for development/testing only
⚠️ **Data Loss Risk**: No cross-region backups or HA
⚠️ **Performance**: Limited resources may cause slower response times
⚠️ **Security**: Minimal security features enabled

## Deployment Commands

```bash
cd "MVP Deployment/terraform"
terraform init
terraform plan
terraform apply
```

## Monitoring Costs

Monitor your usage in GCP Console:
- **Billing**: https://console.cloud.google.com/billing
- **Free Tier Usage**: Check remaining free tier allowances
- **Set Budget Alerts**: Recommended at $100/month threshold