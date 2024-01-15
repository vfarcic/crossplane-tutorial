#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p gum kind kubectl yq google-cloud-sdk awscli2 eksctl azure-cli

set -e

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Setup for the Managed Resources chapter.
  
This script assumes that you jumped straight into this chapter.
If that is not the case (if you are continuing from the previous
chapter), please answer with "No" when asked whether you are
ready to start.'

gum confirm '
Are you ready to start?
Select "Yes" only if you did NOT follow the story from the start (if you jumped straight into this chapter).
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

rm -f .env

#########################
# Control Plane Cluster #
#########################

kind delete cluster

kind create cluster

##############
# Crossplane #
##############

echo "## Which Hyperscaler do you want to use?" | gum format

HYPERSCALER=$(gum choose "google" "aws" "azure")

echo "export HYPERSCALER=$HYPERSCALER" >> .env

if [[ "$HYPERSCALER" == "google" ]]; then
    
    gcloud auth login

    PROJECT_ID=dot-$(date +%Y%m%d%H%M%S)

    echo "export PROJECT_ID=$PROJECT_ID" >> .env

    gcloud projects create ${PROJECT_ID}

    echo "
Please open https://console.developers.google.com/apis/api/compute.googleapis.com/overview?project=$PROJECT_ID in a browser and *ENABLE* the API."

    gum input --placeholder "
Press the enter key to continue."

    export SA_NAME=devops-toolkit

    export SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

    gcloud iam service-accounts create $SA_NAME \
        --project $PROJECT_ID

    export ROLE=roles/admin

    gcloud projects add-iam-policy-binding \
        --role $ROLE $PROJECT_ID --member serviceAccount:$SA

    gcloud iam service-accounts keys create gcp-creds.json \
        --project $PROJECT_ID --iam-account $SA

    yq --inplace ".spec.projectID = \"$PROJECT_ID\"" \
        providers/google-config.yaml

elif [[ "$HYPERSCALER" == "aws" ]]; then

    AWS_ACCESS_KEY_ID=$(gum input \
        --placeholder "AWS Access Key ID" \
        --value "$AWS_ACCESS_KEY_ID")
    echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env
    
    AWS_SECRET_ACCESS_KEY=$(gum input \
        --placeholder "AWS Secret Access Key" \
        --value "$AWS_SECRET_ACCESS_KEY" --password)
    echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> .env

    AWS_ACCOUNT_ID=$(gum input --placeholder "AWS Account ID" \
        --value "$AWS_ACCOUNT_ID")
    echo "export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID" >> .env

    echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" >aws-creds.conf

else

    AZURE_TENANT_ID=$(gum input --placeholder "Azure Tenant ID" --value "$AZURE_TENANT_ID")

    az login --tenant $AZURE_TENANT_ID

    export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

    az ad sp create-for-rbac --sdk-auth --role Owner \
        --scopes /subscriptions/$SUBSCRIPTION_ID \
        | tee azure-creds.json

fi
