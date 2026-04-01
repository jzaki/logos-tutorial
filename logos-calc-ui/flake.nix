{
  description = "Calculator QML UI Plugin for Logos - frontend for calc_module";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder/46a51e5fc321ac11b966c1cc2a2cff21d36fef95";
    calc_module.url = "github:logos-co/logos-tutorial/tutorial-v1?dir=logos-calc-module";
  };

  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosQmlModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
