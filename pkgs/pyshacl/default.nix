{ pkgs }:

let
  # owlrl is pyshacl's own direct dependency, and likewise unpackaged in
  # nixpkgs - see pkgs/owlrl's own comment.
  owlrl = import ../owlrl { inherit pkgs; };
in
# pyshacl: a SHACL (Shapes Constraint Language) validator for rdflib
# graphs - not packaged in nixpkgs (checked against this flake's pinned
# nixos-25.05 revision), needed for the base profile's document/data
# toolchain (home/tools.nix). Built from PyPI's prebuilt wheel for the
# same reason owlrl is: a pure-Python, universal wheel, nothing to
# compile or detect a build backend for.
pkgs.python3Packages.buildPythonPackage rec {
  pname = "pyshacl";
  version = "0.40.1";
  format = "wheel";

  src = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/03/90/7f35a79db93032ef20db5b740062b54afba32a2c2475a6f0a43c141a69de/pyshacl-${version}-py3-none-any.whl";
    sha256 = "27dd58c8ddfa103303b4a8c40b2c666332ffc912dbcd3137f7adc7b7bc5e6bda";
  };

  # pyshacl's own PyPI metadata also lists `rdflib[html]` (pulling in
  # html5rdf, for parsing RDFa/microdata embedded in HTML documents) -
  # deliberately left off here: it's an optional feature pyshacl only
  # imports lazily when actually asked to parse HTML, not at module load,
  # and this base profile already carries plain `html5lib` (a different,
  # older library) for its own sake, not as a stand-in for this extra.
  propagatedBuildInputs = [
    owlrl
    pkgs.python3Packages.packaging
    pkgs.python3Packages.prettytable
    pkgs.python3Packages.rdflib
  ];

  doCheck = false;
  pythonImportsCheck = [ "pyshacl" ];

  meta = {
    description = "SHACL (Shapes Constraint Language) validator for rdflib graphs, not packaged in nixpkgs";
    homepage = "https://github.com/RDFLib/pySHACL";
    license = pkgs.lib.licenses.asl20;
    mainProgram = "pyshacl";
  };
}
