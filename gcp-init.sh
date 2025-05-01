#!/bin/bash

# chmod +x gcp-init.sh

# Variables:
export BILLING_ACC="01F0C7-9A2082-488963"
export PROJECT_NAME="secretshub"
export PROJECT_ID="${PROJECT_NAME}1"
export REGION="us-central1"

# GCP setting:
gcloud projects create $PROJECT_ID --name=$PROJECT_NAME --labels=owner=guilhermeviegas --enable-cloud-apis
gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACC
gcloud config set project $PROJECT_ID
gcloud config set billing/quota_project $PROJECT_ID
gcloud auth application-default set-quota-project $PROJECT_ID
cd ~/Documents/03-secrets_hub/secrets_hub
gcloud config list

# APIs enabling:
gcloud services enable cloudbilling.googleapis.com --project=$PROJECT_ID
gcloud services enable iam.googleapis.com --project=$PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com --project=$PROJECT_ID
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID
gcloud services enable run.googleapis.com --project=$PROJECT_ID
gcloud services enable container.googleapis.com --project=$PROJECT_ID
gcloud services enable logging.googleapis.com --project=$PROJECT_ID
gcloud services enable monitoring.googleapis.com --project=$PROJECT_ID
gcloud services enable storage.googleapis.com --project=$PROJECT_ID

terraform init 
terraform plan -out=plan.out
terraform apply
terraform state list
# terraform output
terraform graph | dot -Tsvg > terraform-graph.svg


# Create TXT record for domain verification:
## Browse "Google Search Console"
## Copy "TXT Record"
## Paste to registro.br domain registry.



docker buildx build --platform linux/amd64 \
  -t $REGION-docker.pkg.dev/$PROJECT_ID/${PROJECT_NAME}-artifact-repo/frontend-app:latest \
  --push react_app/

