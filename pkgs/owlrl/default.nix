{ pkgs }:

# owlrl: an OWL 2 RL and RDFS reasoner for rdflib graphs - not packaged in
# nixpkgs (checked against this flake's pinned nixos-25.05 revision), but
# needed as pyshacl's (../pyshacl) own direct dependency. Built from
# PyPI's prebuilt wheel rather than its sdist: it's a pure-Python,
# universal (py3-none-any) wheel, so there's no build backend to detect
# or native extension to compile - installing the wheel directly is both
# simpler and faster than building from source for zero actual benefit.
pkgs.python3Packages.buildPythonPackage rec {
  pname = "owlrl";
  version = "7.6.2";
  format = "wheel";

  src = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/4a/5e/314be7440bf28dbd47f85321a7434c5b74179a762228487d6493c01bddce/owlrl-${version}-py3-none-any.whl";
    sha256 = "83347bf7f133979e87b2b18695d51d25510b99cec3f6919b5df05d4fbf058ae0";
  };

  propagatedBuildInputs = [ pkgs.python3Packages.rdflib ];

  # No build step for a wheel install, so there's nothing for nixpkgs'
  # usual pytest-discovery doCheck to run against; the import check below
  # is this package's actual smoke test.
  doCheck = false;
  pythonImportsCheck = [ "owlrl" ];

  meta = {
    description = "OWL 2 RL and RDFS based expansion/reasoning engine for rdflib graphs (a pyshacl dependency, not packaged in nixpkgs)";
    homepage = "https://github.com/RDFLib/OWL-RL";
    license = pkgs.lib.licenses.w3c;
  };
}
