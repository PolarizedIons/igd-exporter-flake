{ fetchFromGitHub, python312, pkgs, ... }:

let
  pname = "igd-exporter";
  versionNumber = "0.0.0";
  version = "${versionNumber}-${builtins.substring 0 7 srcRev}";

  srcOwner = "yrro";
  srcRepo = "igd-exporter";
  srcRev = "c49a8ade4d60ad9f242e5d314c3f55294eccea14";
  srcHash = "sha256-8/un/QSZQZCwbmZ31hb0oBdg40Y/Faq0OUZEgVAuRl0=";

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
