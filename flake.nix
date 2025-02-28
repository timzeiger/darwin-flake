{
  description = "Tims Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages =
        [ pkgs.vim
          pkgs.mkalias
          pkgs.tmux
          pkgs.obsidian
          pkgs.google-chrome
          pkgs.gimp
          pkgs.vscode
          #pkgs.reaper
          pkgs.btop
          pkgs.fastfetch
          pkgs.fzf
          pkgs.neovim
        ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
        ];
        casks = [
          "firefox"
          "thunderbird@esr"
          "the-unarchiver"
          "omnissa-horizon-client"
          "element"
          "nextcloud"
          "dbeaver-community"
          "cheatsheet"
          "spotify"
          "steam"
          "balenaetcher"
	  "vlc"
          "sublime-text"
          "sublime-merge"
        ];
        masApps = {
          "Bitwarden" = 1352778147;
          "Money Money" = 872698314;
          "Little Note" = 6478027539;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    pkgs.lib.mkForce ''
    echo "setting up /Applications..." >&2
    rm -rf /Applications/Nix\ Apps
    mkdir -p /Applications/Nix\ Apps
    find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
    while read src; do
      app_name=$(basename "$src")
      echo "copying $src" >&2
      ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
    done
        '';
      services.nix-daemon.enable = true;
      nix.settings.experimental-features = "nix-command flakes";
      programs.zsh.enable = true;
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 5;
      nixpkgs.hostPlatform = "x86_64-darwin";
    };
  in
  {
    darwinConfigurations.iMac = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = "timzeiger";
          };
        }
      ];
    };
    darwinPackages = self.darwinConfigurations.iMac.pkgs;
  };
}
