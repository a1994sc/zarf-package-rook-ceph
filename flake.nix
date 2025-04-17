{
  description = "Zarf package";

  inputs = {
    # keep-sorted start block=yes case=no
    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    pre-commit-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/pre-commit-hooks.nix";
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
    ascii-pkgs.url = "github:a1994sc/nix-pkgs";
    # keep-sorted end
  };

  outputs =
    inputs@{
      # keep-sorted start
      flake-utils,
      nixpkgs,
      self,
      treefmt-nix,
      # keep-sorted end
      ...
    }:
    flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        zarf = inputs.ascii-pkgs.packages.${system}.zarf;
        treefmtEval = treefmt-nix.lib.evalModule pkgs (
          { pkgs, ... }:
          {
            # keep-sorted start block=yes
            programs.dprint = {
              enable = true;
              includes = [ "**/*.{json,md}" ];
              settings.plugins =
                let
                  dprintWasmPluginUrl = n: v: "https://plugins.dprint.dev/${n}-${v}.wasm";
                in
                [
                  (dprintWasmPluginUrl "json" "0.19.4")
                  (dprintWasmPluginUrl "markdown" "0.17.8")
                ];
            };
            programs.jsonfmt = {
              enable = true;
              package = pkgs.jsonfmt;
            };
            programs.keep-sorted.enable = true;
            programs.nixfmt = {
              enable = true;
              package = pkgs.nixfmt-rfc-style;
            };
            projectRootFile = "flake.nix";
            settings.formatter = {
              # keep-sorted start block=yes
              jsonfmt.includes = [
                "*.json"
                "./.github/*.json"
                "./.vscode/*.json"
              ];
              # keep-sorted end
            };
            # keep-sorted end
          }
        );
        shellHook =
          self.checks.${system}.pre-commit-check.shellHook
          + ''
            export ZARF_CONFIG=$(git rev-parse --show-toplevel)/zarf-config.yaml
          '';
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages ++ [
          (pkgs.writeShellScriptBin "zpkg" ''
            rm -rf $TMPDIR/zarf-*
            rm -rf $TMPDIR/syft-archive-contents-*
            rm -rf $TMPDIR/container_images_storage*
            ${zarf}/bin/zarf package create -o $(git rev-parse --show-toplevel) --log-format=console --confirm $@
          '')
          (pkgs.writeShellScriptBin "zdeploy" ''
            rm -rf $TMPDIR/zarf-*
            ${zarf}/bin/zarf package deploy --confirm --log-format=console $@
          '')
          pkgs.gh
          zarf
          pkgs.oras
        ];
      in
      {
        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # keep-sorted start case=no
              check-executables-have-shebangs.enable = true;
              check-shebang-scripts-are-executable.enable = true;
              end-of-file-fixer.enable = true;
              nixfmt-rfc-style.enable = true;
              trim-trailing-whitespace.enable = true;
              # keep-sorted end
            };
          };
        };
        devShells.default = pkgs.mkShell { inherit shellHook buildInputs; };
        formatter = treefmtEval.config.build.wrapper;
      }
    );
}
