{
  description = "Calculator QML UI Plugin for Logos - frontend for calc_module";

  inputs = {
    logos-cpp-sdk.url = "github:logos-co/logos-cpp-sdk";
    nixpkgs.follows = "logos-cpp-sdk/nixpkgs";
  };

  outputs = { self, nixpkgs, logos-cpp-sdk }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      packages = forAllSystems ({ pkgs }: let
        plugin = pkgs.stdenv.mkDerivation {
          pname = "logos-calc-ui-plugin";
          version = "1.0.0";
          src = ./.;

          dontUnpack = false;
          phases = [ "unpackPhase" "installPhase" ];

          installPhase = ''
            runHook preInstall

            dest="$out/lib"
            mkdir -p "$dest/icons"

            cp $src/Main.qml    "$dest/Main.qml"
            cp $src/metadata.json "$dest/metadata.json"

            # Copy icon if present
            if [ -f "$src/icons/calc.png" ]; then
              cp $src/icons/calc.png "$dest/icons/calc.png"
            fi

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Calculator QML UI Plugin for Logos";
            platforms = platforms.unix;
          };
        };
      in {
        default = plugin;
        lib = plugin;
      });
    };
}
