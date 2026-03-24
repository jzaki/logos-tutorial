{
  description = "Calculator C++ UI plugin for Logos - widget frontend for calc_module";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    logos-standalone-app.url = "github:logos-co/logos-standalone-app";
    calc_module.url = "github:logos-co/logos-tutorial?dir=logos-calc-module";
  };

  outputs = { logos-module-builder, logos-standalone-app, calc_module, ... }:
    logos-module-builder.lib.mkLogosModule {
      src = ./.;
      configFile = ./module.yaml;
      moduleInputs = { inherit calc_module; };
      logosStandalone = logos-standalone-app;
      iconFiles = [ ./icons/calc.png ];
    };
}
