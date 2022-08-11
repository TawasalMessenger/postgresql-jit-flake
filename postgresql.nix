{ callPackage, postgresql, llvmPackages, nukeReferences, patchelf, makeWrapper, buildEnv }:
let
  postgresqlWithPackages = { postgresql, makeWrapper, buildEnv }:
    pkgs: f:
    buildEnv {
      name = "postgresql-and-plugins-${postgresql.version}";
      paths = f pkgs ++ [
        postgresql
        postgresql.lib
        postgresql.man # in case user installs this into environment
      ];
      buildInputs = [ makeWrapper ];

      # We include /bin to ensure the $out/bin directory is created, which is
      # needed because we'll be removing the files from that directory in postBuild
      # below. See #22653
      pathsToLink = [ "/" "/bin" ];

      # Note: the duplication of executables is about 4MB size.
      # So a nicer solution was patching postgresql to allow setting the
      # libdir explicitely.
      postBuild = ''
        mkdir -p $out/bin
        rm $out/bin/{pg_config,postgres,pg_ctl}
        cp --target-directory=$out/bin ${postgresql}/bin/{postgres,pg_config,pg_ctl}
        wrapProgram $out/bin/postgres --set NIX_PGLIBDIR $out/lib
      '';

      passthru.version = postgresql.version;
      passthru.psqlSchema = postgresql.psqlSchema;
    };
  postgresql_jit =
    (postgresql.override { stdenv = llvmPackages.stdenv; }).overrideAttrs (oa: {
      nativeBuildInputs = oa.nativeBuildInputs
        ++ [ llvmPackages.llvm nukeReferences patchelf ];
      configureFlags = oa.configureFlags ++ [ "--with-llvm" ];
      postPatch = ''
        # Force lookup of jit stuff in $out instead of $lib
        substituteInPlace src/backend/jit/jit.c --replace pkglib_path \"$out/lib\"
        substituteInPlace src/backend/jit/llvm/llvmjit.c --replace pkglib_path \"$out/lib\"
        substituteInPlace src/backend/jit/llvm/llvmjit_inline.cpp --replace pkglib_path \"$out/lib\"
      '';

      passthru = postgresql.passthru // {
        withPackages = postgresqlWithPackages {
          inherit makeWrapper buildEnv;
          postgresql = postgresql_jit;
        } postgresql_jit.pkgs;

        pkgs = builtins.mapAttrs
          (_: pkg: pkg.override { postgresql = postgresql_jit; })
          postgresql.pkgs;
      };
      postInstall = oa.postInstall + ''
        # Move the bitcode and libllvmjit.so library out of $lib; otherwise, every client that
        # depends on libpq.so will also have libLLVM.so in its closure too, bloating it
        moveToOutput "lib/bitcode" "$out"
        moveToOutput "lib/llvmjit*" "$out"
        # In the case of JIT support, prevent a retained dependency on clang-wrapper
        substituteInPlace "$out/lib/pgxs/src/Makefile.global" --replace ${llvmPackages.stdenv.cc}/bin/clang clang
        nuke-refs $out/lib/llvmjit_types.bc $(find $out/lib/bitcode -type f)
        # Stop out depending on the default output of llvm
        substituteInPlace $out/lib/pgxs/src/Makefile.global \
          --replace ${llvmPackages.llvm.out}/bin "" \
          --replace '$(LLVM_BINPATH)/' ""
        # Stop out depending on the -dev output of llvm
        substituteInPlace $out/lib/pgxs/src/Makefile.global \
          --replace ${llvmPackages.llvm.dev}/bin/llvm-config llvm-config \
          --replace -I${llvmPackages.llvm.dev}/include ""
        # Stop lib depending on the -dev output of llvm
        rpath=$(patchelf --print-rpath $out/lib/llvmjit.so)
        nuke-refs -e $out $out/lib/llvmjit.so
        # Restore the correct rpath
        patchelf $out/lib/llvmjit.so --set-rpath "$rpath"
      '';
    });
in postgresql_jit
