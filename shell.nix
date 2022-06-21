{ mkShell, postgresql_10_jit, postgresql_11_jit, postgresql_12_jit, postgresql_13_jit, postgresql_14_jit }:

mkShell {
  name = "postgresql-jit";

  buildInputs = [ postgresql_10_jit, postgresql_11_jit, postgresql_12_jit, postgresql_13_jit, postgresql_14_jit ];
}
