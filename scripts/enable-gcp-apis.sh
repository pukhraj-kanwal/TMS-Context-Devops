#!/bin/bash

# Script to enable all required GCP APIs for Gemini TMS Platform
# This script enables APIs for compute, container, SQL, Redis, Pub/Sub, IAM, 
# Artifact Registry, API Gateway, and Secret Manager

set -e

PROJECT_ID=$(gcloud config get-value project)
echo "Enabling APIs for project: $PROJECT_ID"

APIS=(
    "compute.googleapis.com"
    "container.googleapis.com"
    "sqladmin.googleapis.com"
    "redis.googleapis.com"
    "pubsub.googleapis.com"
    "iam.googleapis.com"
    "artifactregistry.googleapis.com"
    "apigee.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "serviceusage.googleapis.com"
    "cloudbilling.googleapis.com"
)

echo "Enabling required APIs..."
for api in "${APIS[@]}"; do
    echo "Enabling $api..."
    gcloud services enable "$api"
done

echo "All APIs have been enabled successfully!"
echo "Verifying enabled services..."
gcloud services list --enabled --filter="name:(${APIS[*]})" --format="table(name,title)"