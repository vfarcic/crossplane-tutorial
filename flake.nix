{
  description = "A development environment for vfarcic's Crossplane Tutorial";

  inputs = {
    # This is just a dummy example illustrating how to pin
    # to multiple nixpkgs versions while not actually doing so.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # If the following line's comment were toggled with the one
    # above, then pkgs below would be pinned to nixos-23.11 instead.
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    # However, currently both nixpkgs and nixpkgs-unstable are pinned
    # to nixos-unstable.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # This enables support for all default systems declared at
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
            buildInputs = with pkgs; [
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
              pkgs_unstable.crossplane-cli
              kubernetes-helm
              pkgs_unstable.kyverno-chainsaw
            ];
          };
        };
      }
    );
}
