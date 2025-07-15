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
  version = "2.18.6";
  pyproject = true;

  src = fetchPypi {
    pname = "ansible_core";
    inherit version;
    hash = "sha256-JbsgzhUWobcweDGyY872hAQ7NyBxFGa9nUFk5f1XZVc=";
  };

  # ansible_connection is already wrapped, so don't pass it through
  # the python interpreter again, as it would break execution of
  # connection plugins.
  postPatch = ''
    substituteInPlace lib/ansible/executor/task_executor.py \
      --replace "[python," "["

    patchShebangs --build packaging/cli-doc/build.py

    SETUPTOOLS_PATTERN='"setuptools[0-9 <>=.,]+"'
    PYPROJECT=$(cat pyproject.toml)
    if [[ "$PYPROJECT" =~ $SETUPTOOLS_PATTERN ]]; then
      echo "setuptools replace: ''${BASH_REMATCH[0]}"
      echo "''${PYPROJECT//''${BASH_REMATCH[0]}/'"setuptools"'}" > pyproject.toml
    else
      exit 2
    fi
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

  # internal import errors, missing dependencies
  doCheck = false;
}
