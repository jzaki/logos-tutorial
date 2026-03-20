{
  description = "Calculator module - wraps libcalc C library for Logos";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    logos-nix.url = "github:logos-co/logos-nix";
    nixpkgs.follows = "logos-nix/nixpkgs";
  };

  outputs = { self, logos-module-builder, nixpkgs, ... }:
    logos-module-builder.lib.mkLogosModule {
      src = ./.;
      configFile = ./module.yaml;
    };
}
