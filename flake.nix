{
  description = "sgk NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # ROS 2 Overlay (Jazzy, Kilted, etc.)
    nix-ros-overlay = {
      url = "github:lopsided98/nix-ros-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Antigravity Flake
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kwin-effects-better-blur-dx = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kwin-effects-glass = {
      url = "github:4v3ngR/kwin-effects-glass";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode-nix = {
      url = "github:dan-online/opencode-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lmstudio-nix = {
      url = "github:Daaboulex/lmstudio-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      nix-ros-overlay,
      antigravity-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # Take the core COSMIC desktop packages from unstable
      cosmicFromUnstable =
        final: prev:
        nixpkgs.lib.genAttrs [
          "cosmic-applets"
          "cosmic-applibrary"
          "cosmic-bg"
          "cosmic-comp"
          "cosmic-edit"
          "cosmic-files"
          "cosmic-greeter"
          "cosmic-icons"
          "cosmic-idle"
          "cosmic-initial-setup"
          "cosmic-launcher"
          "cosmic-notifications"
          "cosmic-osd"
          "cosmic-panel"
          "cosmic-player"
          "cosmic-randr"
          "cosmic-screenshot"
          "cosmic-session"
          "cosmic-settings"
          "cosmic-settings-daemon"
          "cosmic-store"
          "cosmic-term"
          "cosmic-wallpapers"
          "cosmic-workspaces-epoch"
          "xdg-desktop-portal-cosmic"
          "libcosmicAppHook"
        ] (name: pkgsUnstable.${name});
    in
    {
      nixosConfigurations.amakusa = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          {
            nix.settings = {
              substituters = [
                "https://ros.cachix.org/"
              ];
              trusted-public-keys = [
                "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
              ];
            };

            nixpkgs.overlays = [
              nix-ros-overlay.overlays.default
              cosmicFromUnstable
            ];
          }

          # OPTIONAL: only uncomment if the build/session breaks from a
          # stable-module vs unstable-package mismatch. Verify these paths
          # exist in your unstable checkout first.
          # {
          #   disabledModules = [
          #     "services/desktop-managers/cosmic.nix"
          #     "services/display-managers/cosmic-greeter.nix"
          #   ];
          #   imports = [
          #     "${nixpkgs-unstable}/nixos/modules/services/desktop-managers/cosmic.nix"
          #     "${nixpkgs-unstable}/nixos/modules/services/display-managers/cosmic-greeter.nix"
          #   ];
          # }

          ./configuration.nix
        ];
      };
    };
}