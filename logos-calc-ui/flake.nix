{
  description = "Calculator QML UI Plugin for Logos - frontend for calc_module";

  inputs = {
    logos-nix.url = "github:logos-co/logos-nix";
    nixpkgs.follows = "logos-nix/nixpkgs";

    logos-standalone-app.url = "github:logos-co/logos-standalone-app";
    logos-standalone-app.inputs.logos-liblogos.inputs.nixpkgs.follows =
      "logos-nix/nixpkgs";
  };

  outputs = { self, nixpkgs, logos-standalone-app, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in {
      packages = forAllSystems ({ pkgs }: let
        plugin = pkgs.stdenv.mkDerivation {
          pname = "logos-calc-ui-plugin";
          version = "1.0.0";
          src = ./.;
          phases = [ "unpackPhase" "installPhase" ];
          installPhase = ''
            mkdir -p $out/lib/icons
            cp $src/Main.qml      $out/lib/Main.qml
            cp $src/metadata.json $out/lib/metadata.json
            if [ -f "$src/icons/calc.png" ]; then
              cp $src/icons/calc.png $out/lib/icons/calc.png
            fi
          '';
        };
      in { default = plugin; lib = plugin; });

      apps = forAllSystems ({ pkgs }:
        let
          standalone = logos-standalone-app.packages.${pkgs.system}.default;
          plugin = self.packages.${pkgs.system}.default;
          run = pkgs.writeShellScript "run-calc-ui-standalone" ''
            exec ${standalone}/bin/logos-standalone "${plugin}/lib" "$@"
          '';
        in { default = { type = "app"; program = "${run}"; }; }
      );
    };
}
