{ postgresql, llvmPackages, nukeReferences, patchelf }:
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
})
