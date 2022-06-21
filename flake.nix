{
  description = "Postgresql wit JIT option Database flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs }:
    with builtins;
    let
#      #sources = (fromJSON (readFile ./flake.lock)).nodes;
      system = "x86_64-linux";
#      pkgs = nixpkgs.legacyPackages.${system};
#      derivations = with pkgs; import ./build.nix {
#        inherit pkgs;
#      };
      overlay = final: prev: let
        localPkgs = import ./default.nix {pkgs = final;};
      in {
        inherit (localPkgs) postgresql_10_jit postgresql_11_jit postgresql_12_jit postgresql_13_jit postgresql_14_jit;
      };
    in
    packages = import ./default.nix {
        pkgs = import nixpkgs {inherit system;};
    };
    #defaultPackage = forAllSystems (system: self.packages.${system}.sops-init-gpg-key);
    #devShell = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix {};




#    with pkgs; with derivations; rec {
#      packages.${system} = derivations;
#      #defaultPackage.${system} = aerospike-server;
#      legacyPackages.${system} = extend overlay;
#      #devShell.${system} = callPackage ./shell.nix derivations;
#      nixosModule = {
#        nixpkgs.overlays = [ overlay ];
#      };
#      overlay = final: prev: derivations;
#    };
}
