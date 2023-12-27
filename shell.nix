let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in

pkgs.mkShell {
  packages = with pkgs; [
    gum
    git
    gh
    kind
    kubectl
    yq-go
    google-cloud-sdk
    awscli2
    azure-cli
    teller
  ];
}
