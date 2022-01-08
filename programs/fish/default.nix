{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.programs.fish;
in {
  options.orchard.programs.fish = { enable = mkEnableOption "Enable Fish"; };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellInit = ''
        set -U fish_prompt_pwd_dir_length 0

        function fish_greeting
        end

        function find_nix_package
          fd $argv /nix/store -d 1 -t d | head -n 1
        end

        # function __fish_command_not_found_handler --on-event fish_command_not_found
        #   echo "command not found:" $argv
        # end
      '';
    };

    users.users.root.shell = pkgs.fish;
  };
}
