# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix 
      "${inputs.nixos-hardware}/framework/16-inch/amd-ai-300-series/nvidia"
    ];

  # Bootloader.
  #boot.loader.systemd-boot.enable = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = false;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.extraEntries = ''
  menuentry "Pop!_OS" {
    insmod part_gpt
    insmod fat
    insmod chain
    search --fs-uuid --set=root 28BE-DCB5
    chainloader /EFI/systemd/systemd-bootx64.efi
  }

  menuentry "Pop!_OS (direct kernel boot - fallback)" {
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root 5dc49cb6-9897-42b1-b597-a73a4bc91509
    linux /boot/vmlinuz root=UUID=5dc49cb6-9897-42b1-b597-a73a4bc91509 ro quiet splash
    initrd /boot/initrd.img
  }

  menuentry "Windows" {
    insmod part_gpt
    insmod fat
    insmod chain
    search --fs-uuid --set=root B826-717F
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
  }
'';

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "euro";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."sgk" = {
    isNormalUser = true;
    description = "Gregorio Kimpo";
    extraGroups = [ "networkmanager" "wheel"  "adbusers" "dialout" "docker"];
    packages = with pkgs; [
      kdePackages.kate
  #inputs.kwin-effects-better-blur-dx.packages.${pkgs.system}.default
    #  thunderbird
    ];
  };
  #programs.adb.enable = true;

  #users.users."sgk".extraGroups = [ "networkmanager" "wheel" "adbusers" "dialout" "docker" ];
  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  kdePackages.kate
  inputs.kwin-effects-better-blur-dx.packages.${pkgs.system}.default
  klassy
  inputs.kwin-effects-glass.packages.${pkgs.system}.default 
  # --- General development ---
  git
  jq
  gh
  gcc
  gnumake
  cmake
  pkg-config
  python3
  python3Packages.pip
  nodejs_22
  docker-compose
  gnupg

  # --- VSCode ---
  vscode
  vim
  # --- KiCad ---
  kicad

  # --- Android development ---
  android-studio
  android-tools
  jdk17
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:195:0:0";
    nvidiaBusId = "PCI:194:0:0";
  };
}
