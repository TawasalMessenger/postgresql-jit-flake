{ llvmPackages
, autoreconfHook
, postgresql
, curl
, fetchFromGitHub
, lz4
, zstd
, lib
}:

llvmPackages.stdenv.mkDerivation rec {
  pname = "citus";
  version = "11.0.2";

  src = fetchFromGitHub {
    owner = "citusdata";
    repo = "citus";
    rev = "v${version}";
    sha256 = "3GlVCIfjdkjxz1wWIop5SSlx6zSWfQbLotvpo5s+3YU=";
    fetchSubmodules = false;
  };

  buildInputs = [
    postgresql
    curl
    lz4
    zstd.out
  ];

  nativeBuildInputs = [
    autoreconfHook
    zstd.dev
    llvmPackages.llvm
  ];

  # dirty hack to give us a clean install tree
  installPhase = ''
    make install DESTDIR=$NIX_BUILD_TOP/citus-destdir
    mkdir -p $out
    mv $NIX_BUILD_TOP/citus-destdir/nix/store/*/* $out
  '';

  meta = with lib; {
    description = "Postgres Clustering";
    homepage = "https://www.citusdata.com/";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ mkg20001 ];
    inherit (postgresql.meta) platforms;
  };
}
