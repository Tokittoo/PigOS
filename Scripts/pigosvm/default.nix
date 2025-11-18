{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Import the unified shell script
  pigosvmScript = pkgs.writeShellApplication {
    name = "pigosvm";
    runtimeInputs = with pkgs; [
      qemu
      curl
      python3
      git
      coreutils
      findutils
      gnused
      gawk
    ];
    text = builtins.readFile ./pigosvm.sh;
  };
in
{
  defaultPackage = pigosvmScript;

  mkPigOSVM =
    {
      memory ? "4G",
      cpus ? 2,
      extraArgs ? "",
    }:
    pkgs.writeShellApplication {
      name = "run-pigosvm";
      runtimeInputs = [ pigosvmScript ];
      text = ''
        VM_MEMORY="${memory}" VM_CPUS="${toString cpus}" VM_EXTRA_ARGS="${extraArgs}" pigosvm "$@"
      '';
    };
}
