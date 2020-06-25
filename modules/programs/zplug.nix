{ config, lib, pkgs, ... }:

with lib;

let

  zshCfg = config.programs.zsh;

  cfg = zshCfg.zplug;

  relToDotDir = file: (optionalString (zshCfg.dotDir != null)
    (zshCfg.dotDir + "/")) + file;

  pluginsDir = if zshCfg.dotDir != null then
    relToDotDir "plugins" else ".zsh/plugins";

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the plugin.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The plugin tags.";
      };
    };

  });

in {
  options.programs.zsh.zplug = {
    enable = mkEnableOption "zplug - a zsh plugin manager";

    plugins = mkOption {
      default = [ ];
      type = types.listOf pluginModule;
      description = "List of zplug plugins.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zplug ];

    programs.zsh.initExtraBeforeCompInit = ''
      export ZPLUG_HOME=$HOME/${pluginsDir}
      source ${pkgs.zplug}/init.zsh

      ${optionalString (cfg.plugins != [ ]) ''
        ${concatStrings (map (plugin: ''
          zplug "${plugin.name}"${
            optionalString (plugin.tags != [ ]) ''
              ${concatStrings (map (tag: ", ${tag}") plugin.tags)}
            ''
          }
        '') cfg.plugins)}
      ''}

      ! zplug check && zplug install
      zplug load
    '';

  };
}
