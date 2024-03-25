{ pkgs ? import <nixpkgs> {} }:pkgs.mkShell {
  packages = with pkgs; [
    gum
    gh
    kind
    kubectl
    yq-go
    jq
    (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
    # awscli2
    azure-cli
    upbound
    teller
    crossplane-cli
    teller
    kubernetes-helm
  ];
  shellHook =
    ''
      gum style \
	      --foreground 212 --border-foreground 212 --border double \
	      --margin "1 2" --padding "2 4" \
	      'AWS CLI was NOT installed due to a bug in the `awscli2` package.
Please install it manually.'
    '';
}
