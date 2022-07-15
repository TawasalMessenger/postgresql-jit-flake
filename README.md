# postgresql-jit-flake
Postgresql with support JIT and Citus

Warning. Now there is working only one option from two: JIT or Citus. For working both option there is must override "withPackages" option of postgresql or its parameters.

Usage.

In flake.nix

inputs.postgresql-jit-nix.url = "github:TawasalMessenger/postgresql-jit-flake.git";

outputs = inputs@{ ...postgresql-jit-nix... }

nixosConfigurations.<name> = nixpkgs.lib.nixosSystem {

...

  modules = [

    ./configuration.nix

    ...

    postgresql-jit-nix.nixosModule

    ...

  ];

In configuration.nix.

For JIT:

postgresql = {

  enable = true;

  package = pkgs.postgresql_jit_14; # Or postgresql_jit_13 or postgresql_jit_12

  settings = {

    jit = "on";

  };

};

For Citus:
postgresql = {
  enable = true;
  package = package = pkgs.postgresql_jit_14.withPackages(_: [ pkgs.citus_jit_14 ]); # Or 13
  settings = {
    shared_preload_libraries = "citus";
  };
};
