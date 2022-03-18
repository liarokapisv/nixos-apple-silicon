# the Asahi Linux kernel and options that must go along with it

{ config, pkgs, lib, ... }:
{
  config = {
    boot.kernelPackages = pkgs.callPackage ./package.nix {
      crossBuild = config.boot.kernelBuildIsCross;
      _16KBuild = config.boot.kernelBuildIs16K;
    };

    # set a default frequency governor the same way nixos-generate-config does
    # so the necessary bits get properly cross-compiled
    powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

    # our kernel config is weird and doesn't really have any modules
    boot.initrd.availableKernelModules = lib.mkForce [];

    # kernel parameters that are useful for debugging
    boot.consoleLogLevel = 7;
    boot.kernelParams = [
      "earlycon"
      "console=ttySAC0,1500000"
      "console=tty0"
      "debug"
      "boot.shell_on_fail"
    ];

    # U-Boot does not support EFI variables
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    # GRUB has to be installed as removable if the user chooses to use it
    boot.loader.grub = lib.mkDefault {
      version = 2;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };

    nixpkgs.overlays = lib.optional config.boot.kernelBuildIs16K (self: super: {
      # patch libunwind to work with dynamic pagesizes
      libunwind = super.libunwind.overrideAttrs (o: {
        patches = (o.patches or []) ++ [
          (self.fetchpatch {
            url = "https://github.com/libunwind/libunwind/pull/330.patch";
            sha256 = "sha256-z3Hpg98D4UMmrE/LC596RFcyxRTvDjD4k7llDPfz1NI=";
          })
        ];
      });
    });
  };

  options.boot.kernelBuildIsCross = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Set that the Asahi Linux kernel should be cross-compiled.";
  };

  options.boot.kernelBuildIs16K = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Set that the Asahi Linux kernel should be built with 16K pages and various
      software patched to be compatible.

      WARNING: be prepared to spend a couple hours compiling if you choose a
      graphical environment plus this option. You will also need >20GB RAM+swap!
    '';
  };
}