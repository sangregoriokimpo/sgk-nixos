{
  description = "sgk NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # NVIDIA Isaac Sim Flake
    isaac-flake = {
      url = "github:urban-prah/isaac-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    isaac-flake,
    nix-ros-overlay,
    antigravity-nix,
    ...
  }@inputs: {
    nixosConfigurations.amakusa = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
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
          ];
        }
        ./configuration.nix
      ];
    };
  };
}