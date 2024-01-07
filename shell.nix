let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in

pkgs.mkShell {
  packages = with pkgs; [
    gum
    gh
    kind
    kubectl
    yq-go
    jq
    google-cloud-sdk
    awscli2
    azure-cli
    upbound
    teller
  ];
  shellHook =
  ''
    curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
    mkdir -p bin
    mv crossplane bin/.
    export PATH=$PWD/bin:$PATH
  '';
}
