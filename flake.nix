{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };
  outputs = inputs@{ self, nixpkgs, ... }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    pkl = import ./pkl.nix pkgs;
  in {
    lib = pkl;
  };
}
