# 19. Security and Compliance Framework

## 1. Executive Summary

This document outlines the comprehensive security and compliance framework for the Gemini TMS platform. Our security strategy implements defense-in-depth principles with zero-trust architecture, ensuring compliance with SOC 2, GDPR, and transportation industry regulations (DOT/FMCSA).

## 2. Security Architecture Overview

### 2.1. Zero-Trust Security Model

**Core Principles:**
- Never trust, always verify
- Least privilege access
- Assume breach and limit impact
- Continuous monitoring and validation

**Implementation Framework:**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Access   │───▶│   Identity &     │───▶│   Application   │
│   (MFA + SSO)   │    │   Access Mgmt    │    │   Services      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Network       │    │   Data           │    │   Infrastructure│
│   Security      │    │   Protection     │    │   Security      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### 2.2. Security Layers Implementation

**Layer 1: Edge Security**
- Cloud CDN with DDoS protection
- Web Application Firewall (WAF)
- TLS 1.3 encryption for all connections
- Rate limiting and traffic analysis

**Layer 2: Network Security**
- VPC with private subnets
- Network segmentation by service tier
- Firewall rules with least privilege
- VPC Flow Logs for network monitoring

**Layer 3: Application Security**
- OAuth 2.0 + OpenID Connect authentication
- JWT tokens with short expiration
- API rate limiting and throttling
- Input validation and sanitization

**Layer 4: Data Security**
- Encryption at rest (AES-256)
- Encryption in transit (TLS 1.3)
- Field-level encryption for PII
- Database access controls and auditing

## 3. Identity and Access Management (IAM)

### 3.1. Authentication Strategy

**Multi-Factor Authentication (MFA):**
- Required for all user accounts
- TOTP (Time-based One-Time Password) primary method
- SMS backup for emergency access
- Hardware tokens for privileged accounts

**Single Sign-On (SSO) Integration:**
```yaml
# OIDC Configuration Example
oidc_providers:
  - name: "google_workspace"
    issuer: "https://accounts.google.com"
    client_id: "${GOOGLE_CLIENT_ID}"
    client_secret: "${GOOGLE_CLIENT_SECRET}"
    scopes: ["openid", "profile", "email"]
    
  - name: "azure_ad"
    issuer: "https://login.microsoftonline.com/${TENANT_ID}/v2.0"
    client_id: "${AZURE_CLIENT_ID}"
    client_secret: "${AZURE_CLIENT_SECRET}"
```

### 3.2. Authorization Framework

**Role-Based Access Control (RBAC):**
```yaml
# Role Definitions
roles:
  super_admin:
    permissions:
      - "company:*"
      - "user:*"
      - "system:*"
    
  company_admin:
    permissions:
      - "company:read:own"
      - "company:write:own"
      - "driver:*:own"
      - "asset:*:own"
    
  dispatcher:
    permissions:
      - "company:read:own"
      - "driver:read:own"
      - "load:*:own"
      - "dispatch:*:own"
    
  driver:
    permissions:
      - "driver:read:self"
      - "driver:write:self"
      - "load:read:assigned"
      - "location:write:self"
```

**Attribute-Based Access Control (ABAC):**
- Company isolation by `company_id`
- Geographic restrictions for sensitive operations
- Time-based access controls
- Device trust levels

### 3.3. Service-to-Service Authentication

**Workload Identity (GKE):**
```yaml
# Service Account Configuration
apiVersion: v1
kind: ServiceAccount
metadata:
  name: company-service-sa
  namespace: production
  annotations:
    iam.gke.io/gcp-service-account: company-service@cargolynx-main.iam.gserviceaccount.com

---
# Workload Identity Binding
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: company-service-gsa
spec:
  accountId: company-service
  displayName: "Company Service Account"
```

**mTLS for Internal Communication:**
- Certificate-based authentication between services
- Automatic certificate rotation
- Service mesh integration (Istio)

## 4. Data Protection and Privacy

### 4.1. Data Classification

**Data Sensitivity Levels:**
- **Public:** Marketing materials, documentation
- **Internal:** Business metrics, operational data
- **Confidential:** Customer data, financial information
- **Restricted:** PII, PHI, payment information

**Data Handling Requirements:**
```yaml
data_classification:
  restricted:
    encryption: "AES-256"
    storage: "encrypted_volumes"
    transit: "TLS_1.3"
    backup: "encrypted_cross_region"
    retention: "7_years"
    access_logging: "required"
    
  confidential:
    encryption: "AES-256"
    storage: "encrypted_volumes"
    transit: "TLS_1.3"
    backup: "encrypted_regional"
    retention: "3_years"
    access_logging: "required"
```

### 4.2. Encryption Implementation

**At-Rest Encryption:**
- Database: Cloud SQL with customer-managed encryption keys (CMEK)
- Storage: Cloud Storage with default encryption
- Secrets: Secret Manager with automatic rotation
- Backups: Encrypted with separate keys

**In-Transit Encryption:**
- All external communication via TLS 1.3
- Internal service communication via mTLS
- Database connections encrypted
- Message queues encrypted (Pub/Sub)

**Field-Level Encryption:**
```python
# Example: PII Encryption
from cryptography.fernet import Fernet
import os

class PIIEncryption:
    def __init__(self):
        self.key = os.environ.get('PII_ENCRYPTION_KEY')
        self.cipher = Fernet(self.key)
    
    def encrypt_field(self, plaintext: str) -> str:
        return self.cipher.encrypt(plaintext.encode()).decode()
    
    def decrypt_field(self, ciphertext: str) -> str:
        return self.cipher.decrypt(ciphertext.encode()).decode()

# Usage in data models
class Driver(BaseModel):
    id: str
    company_id: str
    name: str
    ssn: str = Field(alias="encrypted_ssn")  # Encrypted at application level
    license_number: str = Field(alias="encrypted_license")
```

### 4.3. Data Loss Prevention (DLP)

**Automated Detection:**
- Credit card numbers (PCI DSS)
- Social Security Numbers
- Driver's license numbers
- Medical information

**Prevention Controls:**
- API response filtering
- Database query monitoring
- File upload scanning
- Email attachment screening

## 5. Compliance Framework

### 5.1. SOC 2 Type II Compliance

**Trust Services Criteria:**

**Security:**
- Access controls and authentication
- Logical and physical security
- Network security controls
- Secure system development

**Availability:**
- 99.9% uptime commitment
- Disaster recovery procedures
- Monitoring and incident response
- Capacity planning and management

**Processing Integrity:**
- Data validation and error handling
- System monitoring and alerting
- Change management procedures
- Quality assurance processes

**Confidentiality:**
- Data classification and handling
- Access controls and encryption
- Secure disposal procedures
- Confidentiality agreements

**Privacy:**
- Privacy notice and consent
- Data collection and usage limits
- Data retention and disposal
- Individual access rights

### 5.2. GDPR Compliance

**Data Protection Principles:**
- Lawfulness, fairness, and transparency
- Purpose limitation
- Data minimization
- Accuracy
- Storage limitation
- Integrity and confidentiality
- Accountability

**Individual Rights Implementation:**
```python
# GDPR Rights API Implementation
from fastapi import APIRouter, Depends
from .auth import get_current_user
from .gdpr import GDPRService

gdpr_router = APIRouter(prefix="/gdpr")

@gdpr_router.get("/data-export")
async def export_personal_data(user: User = Depends(get_current_user)):
    """Right to Data Portability (Article 20)"""
    return await GDPRService.export_user_data(user.id)

@gdpr_router.delete("/data-deletion")
async def delete_personal_data(user: User = Depends(get_current_user)):
    """Right to Erasure (Article 17)"""
    return await GDPRService.delete_user_data(user.id)

@gdpr_router.patch("/data-rectification")
async def rectify_personal_data(
    updates: Dict[str, Any],
    user: User = Depends(get_current_user)
):
    """Right to Rectification (Article 16)"""
    return await GDPRService.update_user_data(user.id, updates)
```

**Privacy by Design Implementation:**
- Data minimization in collection
- Pseudonymization techniques
- Consent management system
- Privacy impact assessments

### 5.3. Transportation Industry Compliance

**DOT/FMCSA Requirements:**
- Electronic Logging Device (ELD) compliance
- Hours of Service (HOS) regulations
- Driver qualification records
- Vehicle inspection reports
- Accident reporting procedures

**Compliance Monitoring:**
```yaml
# Compliance Checks
compliance_rules:
  hos_violations:
    check: "daily_driving_hours > 11"
    action: "alert_dispatcher"
    severity: "high"
    
  eld_connectivity:
    check: "last_ping > 30_minutes"
    action: "alert_driver"
    severity: "medium"
    
  inspection_due:
    check: "days_since_inspection > 365"
    action: "schedule_inspection"
    severity: "high"
```

## 6. Security Monitoring and Incident Response

### 6.1. Security Information and Event Management (SIEM)

**Log Sources:**
- Application security events
- Infrastructure access logs
- Network traffic analysis
- Cloud audit logs
- Container security events

**Detection Rules:**
```yaml
# Security Alert Rules
security_rules:
  - rule_name: "suspicious_login_attempts"
    condition: "failed_logins > 5 in 5m"
    severity: "medium"
    action: "block_ip"
    
  - rule_name: "privilege_escalation"
    condition: "role_change and new_role contains 'admin'"
    severity: "high"
    action: "alert_security_team"
    
  - rule_name: "data_exfiltration"
    condition: "data_export_size > 100MB"
    severity: "critical"
    action: "alert_and_block"
```

### 6.2. Incident Response Procedures

**Incident Classification:**
- **P1 (Critical):** Active breach, data compromise
- **P2 (High):** Potential breach, system compromise
- **P3 (Medium):** Security policy violation
- **P4 (Low):** Security awareness, minor issues

**Response Timeline:**
- **Detection:** Automated monitoring < 5 minutes
- **Assessment:** Security team response < 15 minutes
- **Containment:** Immediate action < 30 minutes
- **Investigation:** Root cause analysis < 24 hours
- **Recovery:** Service restoration < 4 hours
- **Lessons Learned:** Post-incident review < 48 hours

### 6.3. Threat Intelligence

**Sources:**
- MITRE ATT&CK framework
- Industry threat feeds
- Government security advisories
- Vulnerability databases (CVE, NVD)

**Threat Modeling:**
- STRIDE methodology
- Attack surface analysis
- Risk assessment matrix
- Mitigation strategies

## 7. Vulnerability Management

### 7.1. Vulnerability Assessment

**Regular Scanning:**
- Weekly infrastructure scans
- Daily container image scans
- Monthly penetration testing
- Quarterly third-party assessments

**Scanning Tools:**
```yaml
# Security Scanning Pipeline
vulnerability_scanning:
  code_analysis:
    tools: ["SonarQube", "CodeQL", "Semgrep"]
    frequency: "on_commit"
    
  dependency_check:
    tools: ["OWASP Dependency Check", "Snyk", "WhiteSource"]
    frequency: "daily"
    
  infrastructure_scan:
    tools: ["Nessus", "OpenVAS", "Qualys"]
    frequency: "weekly"
    
  container_scan:
    tools: ["Twistlock", "Aqua Security", "Clair"]
    frequency: "on_build"
```

### 7.2. Patch Management

**Patching Strategy:**
- **Critical vulnerabilities:** 24 hours
- **High vulnerabilities:** 72 hours
- **Medium vulnerabilities:** 7 days
- **Low vulnerabilities:** 30 days

**Automated Patching:**
```bash
#!/bin/bash
# Automated patch deployment script

# Security patches (immediate)
if [[ "$SEVERITY" == "CRITICAL" ]]; then
    kubectl patch deployment $DEPLOYMENT_NAME -p '{"spec":{"template":{"spec":{"containers":[{"name":"'$CONTAINER_NAME'","image":"'$NEW_IMAGE'"}]}}}}'
    kubectl rollout status deployment/$DEPLOYMENT_NAME
fi

# Staging environment testing
if [[ "$ENVIRONMENT" == "staging" ]]; then
    # Run security tests
    ./scripts/security-tests.sh
    # Performance regression tests
    ./scripts/performance-tests.sh
fi
```

## 8. Secure Development Lifecycle (SDLC)

### 8.1. Security Requirements

**Development Phase Security:**
- Threat modeling during design
- Security code reviews
- Static application security testing (SAST)
- Dynamic application security testing (DAST)

**CI/CD Security Integration:**
```yaml
# .github/workflows/security-pipeline.yml
name: Security Pipeline
on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run SAST
        uses: github/super-linter@v4
        env:
          VALIDATE_SECURITY: true
          
      - name: Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        
      - name: Container Scan
        uses: anchore/scan-action@v3
        with:
          image: ${{ env.IMAGE_NAME }}:${{ github.sha }}
          
      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: results.sarif
```

### 8.2. Secure Coding Standards

**Code Review Checklist:**
- [ ] Input validation implemented
- [ ] SQL injection prevention
- [ ] XSS protection measures
- [ ] Authentication and authorization
- [ ] Error handling (no information disclosure)
- [ ] Logging security events
- [ ] Secrets management
- [ ] Cryptographic implementations

## 9. Third-Party Security

### 9.1. Vendor Risk Assessment

**Security Questionnaire:**
- Data handling practices
- Security certifications
- Incident response procedures
- Access controls
- Encryption standards
- Compliance status

**Ongoing Monitoring:**
- Security rating services
- Vulnerability disclosures
- Compliance audit results
- Incident notifications

### 9.2. Supply Chain Security

**Software Dependencies:**
- Dependency vulnerability scanning
- License compliance checking
- Supply chain attack prevention
- Trusted package repositories

**Infrastructure Dependencies:**
- Cloud provider security assessments
- Network provider security standards
- Hardware vendor security practices
- Third-party service integrations

## 10. Security Training and Awareness

### 10.1. Security Training Program

**All Personnel:**
- Security awareness training (annual)
- Phishing simulation exercises (quarterly)
- Incident reporting procedures
- Data handling best practices

**Development Team:**
- Secure coding practices
- OWASP Top 10 training
- Threat modeling workshops
- Security tool usage

**Operations Team:**
- Infrastructure security
- Incident response procedures
- Forensics and analysis
- Compliance requirements

### 10.2. Security Metrics and KPIs

**Security Posture Metrics:**
- Mean time to patch critical vulnerabilities
- Security training completion rate
- Phishing simulation click rate
- Compliance audit findings
- Incident response time

**Operational Security Metrics:**
- Failed authentication attempts
- Privilege escalation events
- Data access anomalies
- Security alert resolution time

## 11. Audit and Compliance Reporting

### 11.1. Audit Trail Requirements

**Comprehensive Logging:**
- User authentication and authorization
- Data access and modifications
- System configuration changes
- Privilege escalations
- Failed access attempts

**Log Retention:**
- Real-time: 30 days
- Archived: 7 years
- Immutable storage
- Cryptographic integrity

### 11.2. Compliance Reporting

**Automated Compliance Checks:**
```python
# Compliance Monitoring Example
class ComplianceMonitor:
    def check_gdpr_compliance(self):
        """Check GDPR compliance requirements"""
        checks = {
            'data_retention': self.check_data_retention_policies(),
            'consent_management': self.check_consent_records(),
            'data_processing': self.check_processing_agreements(),
            'breach_notification': self.check_breach_procedures()
        }
        return all(checks.values())
    
    def check_soc2_compliance(self):
        """Check SOC 2 compliance requirements"""
        return {
            'access_controls': self.audit_access_controls(),
            'encryption': self.verify_encryption_standards(),
            'monitoring': self.check_monitoring_coverage(),
            'incident_response': self.verify_incident_procedures()
        }
```

This comprehensive security and compliance framework ensures that the Gemini TMS platform maintains the highest security standards while meeting all regulatory requirements for transportation management systems.