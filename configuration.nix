# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  system = pkgs.stdenv.hostPlatform.system;

  # One merged ROS 2 Jazzy environment (instead of listing ros-core from
  # two distros, which collide in a single profile).
  rosJazzy = pkgs.rosPackages.jazzy.buildEnv {
    paths = with pkgs.rosPackages.jazzy; [
      ros-core
      rviz2
      xacro
      robot-state-publisher
      joint-state-publisher-gui
      ros2-control
      ros2-controllers
      rqt-graph
      tf2-tools
      rosbag2
      teleop-twist-keyboard
      # ros-gz  # see note: may clash with gz-harmonic below; try it in a dev shell first
    ];
  };

  # Python with MuJoCo + common sim deps (pip is included).
  pythonSim = pkgs.python3.withPackages (
    ps: with ps; [
      pip
      mujoco
      numpy
      scipy
      matplotlib
      glfw
    ]
  );

  # gz-harmonic with the old Ubuntu bashrc fix baked in:
  # force X11/XWayland (unset WAYLAND_DISPLAY) + render on the NVIDIA GPU.
  gzOffload = pkgs.symlinkJoin {
    name = "gz-harmonic-offload";
    paths = [ inputs.gazebros2nix.packages.${system}.gz-harmonic ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/gz \
        --unset WAYLAND_DISPLAY \
        --set __NV_PRIME_RENDER_OFFLOAD 1 \
        --set __GLX_VENDOR_LIBRARY_NAME nvidia
    '';
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    "${inputs.nixos-hardware}/framework/16-inch/amd-ai-300-series/nvidia"
  ];

  # Bootloader.
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

  networking.hostName = "amakusa";

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
  services.xserver.enable = true;

  # --- Display Manager: COSMIC Greeter ---
  services.displayManager.sddm.enable = false;
  services.displayManager.cosmic-greeter.enable = true;

  # --- Desktop Environments & Window Managers ---
  # COSMIC DE
  services.desktopManager.cosmic.enable = true;
  services.system76-scheduler.enable = true;

  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Wayland hint for Electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
  };

  # Define a user account.
  users.users."sgk" = {
    isNormalUser = true;
    description = "Gregorio Kimpo";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "dialout"
      "docker"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # --- KDE Extras ---
    kdePackages.kate
    inputs.kwin-effects-better-blur-dx.packages.${pkgs.stdenv.hostPlatform.system}.default
    klassy
    inputs.kwin-effects-glass.packages.${pkgs.stdenv.hostPlatform.system}.default

    # --- COSMIC applets & extras (from unstable) ---
    unstable.cosmic-ext-applet-caffeine
    unstable.cosmic-ext-applet-external-monitor-brightness
    unstable.cosmic-ext-applet-mare-player
    unstable.cosmic-ext-applet-minimon
    unstable.cosmic-ext-applet-privacy-indicator
    unstable.cosmic-ext-applet-sysinfo
    unstable.cosmic-ext-applet-weather
    unstable.cosmic-ext-applet-workspace-icons
    unstable.cosmic-ext-ctl
    unstable.cosmic-ext-tweaks
    unstable.cosmic-ext-calculator
    unstable.tasks
    unstable.cosmic-reader
    unstable.cosmic-viewer
    unstable.cosmic-osk

    # --- Hyprland Tools & Utilities ---
    kitty
    wofi
    waybar
    dunst
    hyprpaper
    wl-clipboard

    # --- General Development ---
    git
    jq
    gh
    gcc
    gnumake
    cmake
    pkg-config
    pythonSim # python3 + pip + mujoco/numpy/scipy/matplotlib/glfw
    nodejs_22
    docker-compose
    gnupg

    # --- ROS Tools & Packages ---
    colcon
    rosJazzy

    # --- Simulation: Gazebo + MuJoCo ---
    # hiPrio so this gz (with sim) beats the gz bundled in the ROS env
    (lib.hiPrio gzOffload)
    mujoco # C library + simulate viewer
    glfw
    libGL

    # --- VSCode & Editors ---
    vscode
    vim

    # --- KiCad ---
    kicad

    # --- Android Development ---
    android-studio
    android-tools
    jdk17

    # --- Gaming ---
    discord
    spotify
    vinegar

    # --- AI / Robotics Dev ---
    inputs.opencode-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.lmstudio-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ollama-cuda
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.nsight_systems   # system-wide profiler
    cudaPackages.nsight_compute   # CUDA kernel profiler
    cudaPackages.nccl             # multi-GPU communication (PyTorch/distributed)
    cudaPackages.libcutensor         # tensor ops library, used by some ML/sim libs
    cudaPackages.cuda_gdb         # CUDA debugger
    cudaPackages.cuda_sanitizer_api  # compute-sanitizer for memory errors
    cudaPackages.libcudss            # sparse direct solvers
    cudaPackages.libcusparse_lt        # sparse matmul, needed by some PyTorch builds


    # Google Antigravity
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default

    # --- Misc ---
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    google-chrome
    onlyoffice-desktopeditors

    # --- NixOS ---
    unstable.fetch
    nerd-fonts.jetbrains-mono
    warp-terminal
    waveterm
    htop
    btop-cuda
    nvtopPackages.nvidia   # GPU monitor

    # --- Terminals ---
    ghostty
  ];

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      format = "[╭─](bold #5277C3)$username$hostname$directory$git_branch$git_status$nix_shell$cmd_duration$line_break[╰─](bold #5277C3)$character";

      os = {
        disabled = false;
        style = "bold #7EBAE4";
        format = "[$symbol]($style) ";
        symbols.NixOS = builtins.fromJSON ''"\uf313"'';
      };

      username = {
        show_always = true;
        style_user = "bold #7EBAE4";
        style_root = "bold red";
        format = "[$user]($style) ";
      };

      hostname = {
        ssh_only = false;
        format = "[@$hostname]($style) ";
        style = "bold #5277C3";
      };

      directory = {
        style = "bold #5277C3";
        truncation_length = 3;
      };

      git_branch.style = "bold #c678dd";

      nix_shell = {
        symbol = " ";
        format = "[$symbol$state]($style) ";
        style = "bold #7EBAE4";
      };

      cmd_duration = {
        min_time = 2000;
        style = "yellow";
      };

      character = {
        success_symbol = "[❯](bold #7EBAE4)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  environment.shellAliases = {
    update_sgk-nix = "sudo nixos-rebuild switch && sudo /etc/nixos/commit.sh && git -C /etc/nixos push";
  };

  system.stateVersion = "26.05";

  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:195:0:0";
    nvidiaBusId = "PCI:194:0:0";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.lact.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      libGL
      libxkbcommon
      vulkan-loader
      udev
      glfw
      # add whatever the debug output says is missing
    ];
  };

  services.flatpak.enable = true;
  system.activationScripts.flathub-remote.text = ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo
  '';
}