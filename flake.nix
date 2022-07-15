{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      overlay = final: prev: {
        postgresql_jit_12 = final.callPackage ./postgresql.nix { postgresql = pkgs.postgresql_12; };
        #citus_jit_12 = final.callPackage ./citus.nix { postgresql = final.postgresql_jit_12; };
        postgresql_jit_13 = final.callPackage ./postgresql.nix { postgresql = pkgs.postgresql_13; };
        citus_jit_13 = final.callPackage ./citus.nix { postgresql = final.postgresql_jit_13; };
        postgresql_jit_14 = final.callPackage ./postgresql.nix { postgresql = pkgs.postgresql_14; };
        citus_jit_14 = final.callPackage ./citus.nix { postgresql = final.postgresql_jit_14; };
      };
      legacyPackages = pkgs.extend self.overlay;

      packages = {
        inherit (self.legacyPackages) postgresql_jit_12 postgresql_jit_13 citus_jit_13 postgresql_jit_14 citus_jit_14;
        #default = with self.packages; postgresql_jit.withPackages (_: [ citus_jit ]);
      };

      nixosModule = {
        nixpkgs.overlays = [ overlay ];
        #services.postgresql.package = pkgs.lib.mkForce self.packages.default;
      };
  };
}