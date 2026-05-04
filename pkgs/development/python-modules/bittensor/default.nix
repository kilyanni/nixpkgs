{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  aiohttp,
  aioresponses,
  async-substrate-interface,
  asyncstdlib,
  bittensor-drand,
  bittensor-wallet,
  colorama,
  cyscale,
  fastapi,
  msgpack-numpy-opentensor,
  netaddr,
  numpy,
  packaging,
  pycryptodome,
  pydantic,
  python-statemachine,
  pyyaml,
  requests,
  retry,
  uvicorn,
  freezegun,
  httpx,
  hypothesis,
  pytest-mock,
  pytestCheckHook,
  pytest-asyncio,
}:

buildPythonPackage (finalAttrs: {
  pname = "bittensor";
  version = "10.3.0";
  pyproject = true;

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "latent-to";
    repo = "bittensor";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+YQdJQoYo//59nR//2Qwp5PMts2CHHv/QWW+lk0I3VE=";
  };

  build-system = [ setuptools ];

  pythonRelaxDeps = [
    "asyncstdlib"
    "python-statemachine"
    "setuptools"
  ];

  dependencies = [
    aiohttp
    async-substrate-interface
    asyncstdlib
    bittensor-drand
    bittensor-wallet
    colorama
    cyscale
    fastapi
    msgpack-numpy-opentensor
    netaddr
    numpy
    packaging
    pycryptodome
    pydantic
    python-statemachine
    pyyaml
    requests
    retry
    setuptools
    uvicorn
  ];

  # bittensor/core/settings.py calls Path.home().mkdir() at import time
  postFixup = ''
    export HOME=$(mktemp -d)
  '';

  nativeCheckInputs = [
    aioresponses
    freezegun
    httpx
    hypothesis
    pytest-mock
    pytestCheckHook
    pytest-asyncio
  ];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  # integration/e2e tests require a live subtensor node; torch tests require optional dep
  disabledTestPaths = [
    "tests/e2e_tests"
    "tests/integration_tests"
    "tests/unit_tests/test_chain_data.py"
    "tests/unit_tests/test_tensor.py"
    "tests/unit_tests/utils/test_weight_utils.py"
  ];

  disabledTests = [
    # requires torch, which would be a very large dependency to pull in for one test
    "test_lazy_loaded_torch__torch_installed"
    # requires network
    "test__methods_comparable_with_passed_legacy_methods"
    # issues with sandbox
    "test_sync_warning_cases"
    # statemachine 3.0 emits extra internal debug logs not expected by the test which expect an older version
    "test_all_log_levels_output"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    # macOS sandbox seems to block loopback connections
    "test_threaded_fastapi"
  ];

  pythonImportsCheck = [ "bittensor" ];

  meta = {
    description = "Bittensor SDK";
    homepage = "https://github.com/latent-to/bittensor";
    changelog = "https://github.com/latent-to/bittensor/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ kilyanni ];
  };
})
