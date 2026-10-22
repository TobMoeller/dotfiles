{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  php,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "laravel-lsp";
  version = "0.0.32";

  # Official portable PHAR; fixed release, with the release asset's SHA-256.
  src = fetchurl {
    url = "https://github.com/laravel/lsp/releases/download/v${finalAttrs.version}/laravel-lsp";
    sha256 = "86d43f017b2247f1da428891a84a7db66d1f4443a0858301fe3a0d38482c5a51";
  };
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    install -Dm644 "$src" "$out/share/laravel-lsp/laravel-lsp.phar"
    makeWrapper ${lib.getExe php} "$out/bin/laravel-lsp" \
      --add-flags "$out/share/laravel-lsp/laravel-lsp.phar"
    runHook postInstall
  '';

  meta = {
    description = "Official Laravel language server";
    homepage = "https://github.com/laravel/lsp";
    license = lib.licenses.mit;
    platforms = php.meta.platforms;
    mainProgram = "laravel-lsp";
  };
})
