#!/bin/sh
set -e

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Setup for the Compositions chapter'

gum confirm '
Are you ready to start?
Select "Yes" only if you did NOT follow the story from the start (if you jumped straight into this chapter).
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

echo "
## You will need following tools installed:
|Name            |Required             |More info                                          |
|----------------|---------------------|---------------------------------------------------|
|Linux Shell     |Yes                  |Use WSL if you are running Windows                 |
|Docker          |Yes                  |'https://docs.docker.com/engine/install'           |
|kind CLI        |Yes                  |'https://kind.sigs.k8s.io/docs/user/quick-start/#installation'|
|kubectl CLI     |Yes                  |'https://kubernetes.io/docs/tasks/tools/#kubectl'  |
|crossplane CLI  |Yes                  |'https://docs.crossplane.io/latest/cli'            |
|yq CLI          |Yes                  |'https://github.com/mikefarah/yq#install'          |
|Google Cloud account with admin permissions|If using Google Cloud|'https://cloud.google.com'|
|Google Cloud CLI|If using Google Cloud|'https://cloud.google.com/sdk/docs/install'        |
|AWS account with admin permissions|If using AWS|'https://aws.amazon.com'                  |
|AWS CLI         |If using AWS         |'https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html'|
|Azure account with admin permissions|If using Azure|'https://azure.microsoft.com'         |
|az CLI          |If using Azure       |'https://learn.microsoft.com/cli/azure/install-azure-cli'|

If you are running this script from **Nix shell**, most of the requirements are already set with the exception of **Docker** and the **hyperscaler account**.
" | gum format

gum confirm "
Do you have those tools installed?
" || exit 0

rm -f .env

set +e

git fetch upstream

git merge upstream/main

set -e

#########################
# Control Plane Cluster #
#########################

kind create cluster --config kind.yaml

kubectl create namespace a-team

##############
# Crossplane #
##############

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

echo "## Which Hyperscaler do you want to use?" | gum format

HYPERSCALER=$(gum choose "google" "aws" "azure")

echo "export HYPERSCALER=$HYPERSCALER" >> .env

if [ "$HYPERSCALER" = "google" ]; then

    gcloud auth login

    PROJECT_ID=dot-$(date +%Y%m%d%H%M%S)

    echo "export PROJECT_ID=$PROJECT_ID" >> .env

    gcloud projects create ${PROJECT_ID}

    echo "## Open https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID and link a billing account" \
        | gum format

    gum input --placeholder "Press the enter key to continue."

    echo "## Open https://console.cloud.google.com/apis/library/sqladmin.googleapis.com?project=$PROJECT_ID and *ENABLE* the API" \
        | gum format

    gum input --placeholder "Press the enter key to continue."

    export SA_NAME=devops-toolkit

    export SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

    gcloud iam service-accounts create $SA_NAME \
        --project $PROJECT_ID

    gcloud projects add-iam-policy-binding \
        --role roles/admin $PROJECT_ID \
        --member serviceAccount:$SA

    gcloud iam service-accounts keys create gcp-creds.json \
        --project $PROJECT_ID --iam-account $SA

    kubectl --namespace crossplane-system \
        create secret generic gcp-creds \
        --from-file creds=./gcp-creds.json

    yq --inplace ".spec.projectID = \"$PROJECT_ID\"" \
        providers/google-config.yaml

elif [ "$HYPERSCALER" = "aws" ]; then

    AWS_ACCESS_KEY_ID=$(gum input --placeholder "AWS Access Key ID" --value "$AWS_ACCESS_KEY_ID")
    echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env
    
    AWS_SECRET_ACCESS_KEY=$(gum input --placeholder "AWS Secret Access Key" --value "$AWS_SECRET_ACCESS_KEY" --password)
    echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> .env

    AWS_ACCOUNT_ID=$(gum input --placeholder "AWS Account ID" --value "$AWS_ACCOUNT_ID")
    echo "export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID" >> .env

    echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" >aws-creds.conf

    kubectl --namespace crossplane-system \
        create secret generic aws-creds \
        --from-file creds=./aws-creds.conf

else

    AZURE_TENANT_ID=$(gum input \
        --placeholder "Azure Tenant ID" \
        --value "$AZURE_TENANT_ID")

    az login --tenant $AZURE_TENANT_ID

    export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

    az ad sp create-for-rbac --sdk-auth --role Owner \
        --scopes /subscriptions/$SUBSCRIPTION_ID \
        | tee azure-creds.json

    kubectl --namespace crossplane-system \
        create secret generic azure-creds \
        --from-file creds=./azure-creds.json

    DB_NAME=my-db-$(date +%Y%m%d%H%M%S)

    echo "---
apiVersion: v1
kind: Secret
metadata:
  name: $DB_NAME-password
data:
  password: T1QrOXZQcDhMdXhoeFVQWVpLSk1kUG1YM04xTzBTd3YzWG5ZVjI0UFZzcz0=
---
apiVersion: devopstoolkitseries.com/v1alpha1
kind: SQLClaim
metadata:
  name: my-db
  annotations:
    organization: DevOps Toolkit
    author: Viktor Farcic <viktor@farcic.com>
spec:
  id: $DB_NAME
  compositionSelector:
    matchLabels:
      provider: azure
      db: postgresql
  parameters:
    version: \"11\"
    size: small" \
    | tee examples/azure-sql-v7.yaml

    echo "---
apiVersion: v1
kind: Secret
metadata:
  name: $DB_NAME-password
data:
  password: T1QrOXZQcDhMdXhoeFVQWVpLSk1kUG1YM04xTzBTd3YzWG5ZVjI0UFZzcz0=
---
apiVersion: devopstoolkitseries.com/v1alpha1
kind: SQLClaim
metadata:
  name: my-db
  annotations:
    organization: DevOps Toolkit
    author: Viktor Farcic <viktor@farcic.com>
spec:
  id: $DB_NAME
  compositionSelector:
    matchLabels:
      provider: azure
      db: postgresql
  parameters:
    version: \"11\"
    size: small
    databases:
      - db-01
      - db-02" \
    | tee examples/azure-sql-v9.yaml

    echo "---
apiVersion: v1
kind: Secret
metadata:
  name: $DB_NAME-password
data:
  password: T1QrOXZQcDhMdXhoeFVQWVpLSk1kUG1YM04xTzBTd3YzWG5ZVjI0UFZzcz0=
---
apiVersion: devopstoolkitseries.com/v1alpha1
kind: SQLClaim
metadata:
  name: my-db
  annotations:
    organization: DevOps Toolkit
    author: Viktor Farcic <viktor@farcic.com>
spec:
  id: $DB_NAME
  compositionSelector:
    matchLabels:
      provider: azure
      db: postgresql
  parameters:
    version: \"11\"
    size: small
    databases:
      - db-01
      - db-02
    schemas:
      - database: db-01
        sql: |
          create table videos (
            id varchar(50) not null,
            description text,
            primary key (id)
          );
          create table comments (
            id serial,
            video_id varchar(50) not null,
            description text not null,
            primary key (id),
            CONSTRAINT fk_videos FOREIGN KEY(video_id) REFERENCES videos(id)
          );" \
    | tee examples/azure-sql-v10.yaml

fi

kubectl apply --filename providers/sql-v5.yaml

gum spin --spinner dot \
    --title "Waiting for Crossplane providers..." -- sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=1800s

kubectl apply --filename providers/$HYPERSCALER-config.yaml

kubectl apply --filename compositions/sql-v7/definition.yaml

kubectl apply --filename compositions/sql-v7/aws.yaml

kubectl apply --filename compositions/sql-v7/azure.yaml

kubectl apply --filename compositions/sql-v7/google.yaml

sleep 3

kubectl --namespace a-team apply \
    --filename examples/$HYPERSCALER-sql-v7.yaml

##################
# Atlas Operator #
##################

helm upgrade --install atlas-operator \
    oci://ghcr.io/ariga/charts/atlas-operator \
    --namespace atlas-operator --create-namespace --wait
