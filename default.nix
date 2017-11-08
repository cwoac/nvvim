with import <nixpkgs> {}; {
  nvimEnv = stdenv.mkDerivation {
    name = "python";
    buildInputs = [ python3 xapian xapianBindings vim_configurable ];
  };
}
