{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            ruby_3_4
            bundler
          ];

          shellHook = ''
            export BUNDLE_PATH=".bundler"
            export GEM_PATH=".bundler/ruby/3.4.0"

            export PATH="$PWD/bin:$PATH"
            export PATH=".bundler/ruby/3.4.0/bin:$PATH"
          '';

        };

        packages.default = pkgs.hello;
      }
    );
}
