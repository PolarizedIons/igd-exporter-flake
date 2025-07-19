{ self, system, pkgs }:

pkgs.nixosTest {
  name = "igd-exporter test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.${system}.igd-exporter ];

    config.services.prometheus.exporters.igd-exporter.enable = true;
  };

  testScript = ''
    machine.wait_for_unit("prometheus-igd-exporter-exporter")
    machine.wait_for_open_port(9196)
  '';
}
