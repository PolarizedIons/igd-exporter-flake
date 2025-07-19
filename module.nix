{ self, system }:
{ lib, config, ... }:

let
  name = "igd-exporter";
  port = 9196;
  cfg = config.services.prometheus.exporters.${name};
  nftables = config.networking.nftables.enable;

  package = self.packages.${system}.${name};

in with lib; {
  options.services.prometheus.exporters.${name} = {
    enable = mkEnableOption "Enable ${name}";
    port = mkOption {
      type = types.port;
      default = port;
      description = "Port to listen on";
    };
    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to listen on";
    };
    ipv6-only = mkOption {
      type = types.bool;
      default = false;
      description = "Bind to IPv6 only, otherwise IPv4 & IPv6 are allowed";
    };
    thread-count = mkOption {
      type = types.int;
      default = 0;
      description =
        "How many request-handling threads to spawn. Default (0) = auto";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "OPen port in firewall for incoming connections";
    };
    firewallFilter = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = literalExpression ''
        "-i eth0 -p tcp -m tcp --dport ${toString port}"
      '';
      description = ''
        Specify a filter for iptables to use when
        {option}`services.prometheus.exporters.${name}.openFirewall`
        is true. It is used as `ip46tables -I nixos-fw firewallFilter -j nixos-fw-accept`.
      '';
    };
    firewallRules = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = literalExpression ''
        iifname "eth0" tcp dport ${toString port} counter accept
      '';
      description = ''
        Specify rules for nftables to add to the input chain
        when {option}`services.prometheus.exporters.${name}.openFirewall` is true.
      '';
    };
    user = mkOption {
      type = types.str;
      default = "${name}-exporter";
      description = ''
        User name under which the ${name} exporter shall be run.
      '';
    };
    group = mkOption {
      type = types.str;
      default = "${name}-exporter";
      description = ''
        Group under which the ${name} exporter shall be run.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      description = "Prometheus ${name} exporter servcie user";
      isSystemUser = true;
      inherit (cfg) group;
    };
    users.groups.${cfg.group} = { };

    networking.firewall.extraCommands = mkIf (cfg.openFirewall && !nftables)
      (concatStrings [
        "ip46tables -A nixos-fw ${cfg.firewallFilter} "
        "-m comment --comment ${name}-exporter -j nixos-fw-accept"
      ]);
    networking.firewall.extraInputRules =
      mkIf (cfg.openFirewall && nftables) cfg.firewallRules;
    systemd.services."prometheus-${name}-exporter" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = ''
          ${package}/bin/${name} \
          --bind-address ${cfg.listenAddress} \
          --bind-port ${toString cfg.port} \
          --bind-v6only ${if cfg.ipv6-only then "1" else "0"}
          ${if cfg.thread-count > 0 then
            "--thread-count ${cfg.thread-count}"
          else
            ""}
        '';

        Restart = mkDefault "always";
        PrivateTmp = mkDefault true;
        WorkingDirectory = mkDefault /tmp;
        DynamicUser = false; # TODO?
        User = mkDefault cfg.user;
        Group = cfg.group;
        # Hardening
        CapabilityBoundingSet = mkDefault [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = mkDefault true;
        ProtectClock = mkDefault true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = mkDefault "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
