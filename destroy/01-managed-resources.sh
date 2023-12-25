#!/bin/sh
set -e

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Destruction of the Managed Resources chapter'

gum confirm '
Are you ready to start?
Select "Yes" only if you did NOT follow the story from the start (if you jumped straight into this chapter).
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

###############
# Hyperscaler #
###############

if [[ "$HYPERSCALER" == "google" ]]; then

	gcloud projects delete $PROJECT_ID --quiet

fi

#########################
# Control Plane Cluster #
#########################

kind delete cluster
