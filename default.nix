with import <nixpkgs> {}; {
  nvvimEnv = stdenv.mkDerivation {
    name = "python";
    buildInputs = [ python3 xapian xapianBindings vim_configurable ];
  };
}
