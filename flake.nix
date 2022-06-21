{
  description = "Postgresql wit JIT option Database flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs }:
    with builtins;
    let
      #sources = (fromJSON (readFile ./flake.lock)).nodes;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      derivations = with pkgs; import ./build.nix {
        inherit pkgs;
      };
    in
    with pkgs; with derivations; rec {
      packages.${system} = derivations;
      #defaultPackage.${system} = aerospike-server;
      legacyPackages.${system} = extend overlay;
      devShell.${system} = callPackage ./shell.nix derivations;
      nixosModule = {
        nixpkgs.overlays = [ overlay ];
      };
      overlay = final: prev: derivations;
    };
}
