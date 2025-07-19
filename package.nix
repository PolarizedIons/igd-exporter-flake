{ fetchFromGitHub, python312, pkgs, ... }:

let
  pname = "igd-exporter";
  versionNumber = "0.0.0";
  version = "${versionNumber}-${builtins.substring 0 7 srcRev}";

  srcOwner = "fatpat";
  srcRepo = "igd-exporter";
  srcRev = "68fbb6a2e89a0f86c5dea444d8fadb708c3e054d";
  srcHash = "sha256-5UX+a+DnSyL6wYCU4hbSbh6PD+dk81E2CpwotFttedE=";

  python = python312;
  buildPython = python.pkgs.buildPythonApplication;

in buildPython {
  inherit pname version;

  pyproject = true;
  build-system = (with python.pkgs; [ setuptools ]) ++ (with pkgs; [ git ]);
  dependencies = (with python.pkgs; [ prometheus-client ]);

  src = fetchFromGitHub {
    owner = srcOwner;
    repo = srcRepo;
    rev = srcRev;
    sha256 = srcHash;

    leaveDotGit = true;
  };
}
