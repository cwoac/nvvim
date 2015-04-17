with import <nixpkgs> {}; {
  nvimEnv = stdenv.mkDerivation {
    name = "python";
    buildInputs = [ python27 xapian xapianBindings vim_configurable ];
  };
}
