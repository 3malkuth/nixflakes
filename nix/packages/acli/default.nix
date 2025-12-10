{ stdenv
, fetchurl
, lib
}:

stdenv.mkDerivation rec {
  pname = "acli";
  version = "latest";

  src = fetchurl {
    url = if stdenv.hostPlatform.isAarch64
      then "https://acli.atlassian.com/linux/latest/acli_linux_arm64/acli"
      else "https://acli.atlassian.com/linux/latest/acli_linux_amd64/acli";
    # Run `nix develop` once - it will fail and show you the correct hash
    # sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    sha256 = "sha256-FBc1FXWcYirVnBneb6y1wstJCoaNXWKRZv2X18UsYOE=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/acli
    chmod +x $out/bin/acli

    runHook postInstall
  '';

  meta = with lib; {
    description = "Atlassian CLI tool";
    homepage = "https://acli.atlassian.com/";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
