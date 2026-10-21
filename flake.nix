{
  description = "mirrorfile — Ruby gem";

  inputs = {
    nixpkgs.url = "nixpkgs";
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, mine, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        # bundlerEnv evaluates the gemspec, so it needs the gemspec and the version it reads.
        # The gemspec parses lib/mirrorfile/version.rb rather than requiring it, so only the
        # gemspec itself is copied and no second copy of the library reaches the load path.
        gemspecFiles = pkgs.runCommand "mirrorfile-gemspec" { } ''
          mkdir -p $out/lib/mirrorfile
          cp ${./mirrorfile.gemspec}        $out/mirrorfile.gemspec
          cp ${./lib/mirrorfile/version.rb} $out/lib/mirrorfile/version.rb
        '';

        gems = pkgs.bundlerEnv {
          name = "mirrorfile-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = ./gemset.nix;
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby
            git
          ];

          shellHook = /* bash */ ''
            export BUNDLE_FORCE_RUBY_PLATFORM=true
            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            # This gem is not in the bundle — it is the repository — so put this lib/ on the
            # load path and let `require "mirrorfile"` find the working tree, and this exe/
            # on PATH so `mirror` is the checkout rather than an installed copy.
            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"
            export PATH="$PWD/exe:$PWD/bin:$PATH"
          '';
        };
      }
    );
}
