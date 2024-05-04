{
  description = "A development environment for vfarcic's Crossplane Tutorial";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # https://github.com/nix-systems/default/blob/main/default.nix
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs = {
        systems.follows = "systems";
      };
    };
  };

  outputs = inputs @ {
    self,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        pkgs_unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in {
        formatter = pkgs.alejandra;

        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs_unstable; [
              gum
              gh
              kind
              kubectl
              yq-go
              jq
              (
                google-cloud-sdk.withExtraComponents
                [google-cloud-sdk.components.gke-gcloud-auth-plugin]
              )
              awscli2
              azure-cli
              upbound
              teller
              crossplane-cli
              kubernetes-helm
              kyverno-chainsaw
            ];
          };
        };
      }
    );
}
