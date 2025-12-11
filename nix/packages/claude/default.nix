{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, makeWrapper
, nodejs_20
}:
stdenv.mkDerivation rec {
  pname = "claude-code";
  version = "2.0.65";

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    sha256 = "b773c30a18b25bf30397af7b32075ed6a4be14227a6c2c1ce16329be5e45de0a";
  };

  nativeBuildInputs = [
    makeWrapper
  ] ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
  ];

  buildInputs = [ nodejs_20 ];

  unpackPhase = ''
    runHook preUnpack
    tar xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/claude-code
    cp -r package/* $out/lib/claude-code/
    mkdir -p $out/bin
    makeWrapper ${nodejs_20}/bin/node $out/bin/claude \
      --add-flags "$out/lib/claude-code/cli.js"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - AI-powered coding assistant CLI";
    homepage = "https://claude.ai/code";
    license = licenses.unfree;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}

