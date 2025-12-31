{
  lib,
  buildPythonPackage,
  fetchPypi,
  installShellFiles,
  docutils,
  setuptools,
  cryptography,
  jinja2,
  junit-xml,
  lxml,
  ncclient,
  packaging,
  paramiko,
  ansible-pylibssh,
  pexpect,
  psutil,
  pycrypto,
  pyyaml,
  requests,
  resolvelib,
  scp,
  windowsSupport ? false,
  pywinrm,
  xmltodict,
}:
buildPythonPackage rec {
  pname = "ansible-core";
  version = "2.19.2";
  pyproject = true;

  src = fetchPypi {
    pname = "ansible_core";
    inherit version;
    hash = "sha256-h/y7xJLtFutq2wN5uuCtv2nzzoioRA5+iODc76n4pUw=";
  };

  # ansible_connection is already wrapped, so don't pass it through
  # the python interpreter again, as it would break execution of
  # connection plugins.
  postPatch = ''
    patchShebangs --build packaging/cli-doc/build.py

    SETUPTOOLS_PATTERN='"setuptools[0-9 <>=.,]+"'
    WHEEL_PATTERN='"wheel[0-9 <>=.,]+"'
    echo "Patching pyproject.toml"
    # print replaced patterns to stdout
    sed -r -i -e 's/'"$SETUPTOOLS_PATTERN"'/"setuptools"/w /dev/stdout' \
    -e 's/'"$WHEEL_PATTERN"'/"wheel"/w /dev/stdout' pyproject.toml
  '';

  nativeBuildInputs = [
    installShellFiles
    docutils
  ];

  build-system = [setuptools];

  dependencies =
    [
      # from requirements.txt
      cryptography
      jinja2
      packaging
      pyyaml
      resolvelib
      # optional dependencies
      junit-xml
      lxml
      ncclient
      paramiko
      ansible-pylibssh
      pexpect
      psutil
      pycrypto
      requests
      scp
      xmltodict
    ]
    ++ lib.optionals windowsSupport [pywinrm];

  pythonRelaxDeps = ["resolvelib"];

  postInstall = ''
    export HOME="$(mktemp -d)"
    packaging/cli-doc/build.py man --output-dir=man
    installManPage man/*
  '';

  # internal import errors, missing dependencies
  doCheck = false;
}
