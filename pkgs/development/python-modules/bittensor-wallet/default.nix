{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
  libsodium,
  libiconv,
  pytestCheckHook,
  ansible-vault-rw,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "bittensor-wallet";
  version = "4.0.1";
  pyproject = true;

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "latent-to";
    repo = "btwallet";
    tag = "v${finalAttrs.version}";
    hash = "sha256-L774RPoasixvW+0Z4WuJ6eLuazLQscckRU++VCAiFug=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-ETr7XhSmUTqtWDGzJMq5ijaLL8+tqmLJa/ngmzwWiFg=";
  };

  nativeBuildInputs = [
    pkg-config
  ]
  ++ (with rustPlatform; [
    cargoSetupHook
    maturinBuildHook
  ]);

  buildInputs = [
    openssl
    libsodium
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  nativeCheckInputs = [
    pytestCheckHook
    ansible-vault-rw
    setuptools # ansible_vault uses pkg_resources at import time
  ];

  # tests try to write to hardcoded directories in /tmp, which causes permission issues on darwin
  postPatch = lib.optionalString stdenv.hostPlatform.isDarwin ''
    walletTestPath=$(mktemp -d)
    sed -i "s|/tmp/tests_wallets|$walletTestPath/tests_wallets|g" tests/test_wallet.py tests/test_keypair.py

    mockWalletPath=$(mktemp -d)
    sed -i "s|/tmp/mock_wallet|$mockWalletPath|g" bittensor_wallet/mock/wallet_mock.py
  '';

  preCheck = ''
    # remove source package so tests import the installed Rust extension
    rm -rf bittensor_wallet
    # ansible-vault writes to HOME
    export HOME=$(mktemp -d)
  '';

  # test_common_calls.py requires bittensor, which depends on this package, which'd create a circular dependency
  disabledTestPaths = [ "tests/test_common_calls.py" ];

  pythonImportsCheck = [ "bittensor_wallet" ];

  meta = {
    description = "Bittensor wallet implementation";
    homepage = "https://github.com/latent-to/btwallet";
    changelog = "https://github.com/latent-to/btwallet/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ kilyanni ];
  };
})
