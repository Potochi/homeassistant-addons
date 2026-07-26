# ==============================================================================
# home-manager module: sync your Mac (or NixOS box) with the Home Assistant
# Syncthing add-on.
#
# nix-darwin has no services.syncthing, so this is a home-manager module. On
# darwin it installs a launchd agent and pushes devices and folders into the
# running daemon over the REST API - the same mechanism the add-on uses.
#
#   imports = [ ./homeassistant-peer.nix ];
#
# Edit the three constants below. Everything else follows from them.
# ==============================================================================
{ config, ... }:

let
  # Device ID printed by ./gen-identity.sh. Constant, safe to commit: device IDs
  # are public.
  haDeviceId = "CHANGE-ME-CHANGE-ME-CHANGE-ME-CHANGE-ME-CHANGE-ME-CHANGE-ME-CHANG";

  # How this machine reaches Home Assistant. Home Assistant does not roam, this
  # laptop does, so only this side needs a fixed address. The add-on runs on
  # Home Assistant's bridge network, so LAN discovery will not find it.
  haAddress = "tcp://homeassistant.local:22000";

  # This machine's own identity, so its device ID is stable too and Home
  # Assistant can be told about it up front. Point these at sops-nix or
  # agenix secrets; plain paths work as well.
  selfCert = config.sops.secrets."syncthing/cert.pem".path;
  selfKey = config.sops.secrets."syncthing/key.pem".path;
in
{
  services.syncthing = {
    enable = true;

    cert = selfCert;
    key = selfKey;

    # This file is the source of truth for what this machine syncs. Anything
    # added through the web UI is reverted on the next activation.
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      options = {
        urAccepted = -1;
        relaysEnabled = true;
      };

      devices.homeassistant = {
        id = haDeviceId;
        addresses = [ haAddress ];

        # Let Home Assistant hear about the other machines listed here, so a new
        # peer only has to be added in one place.
        introducer = true;
      };

      # Every folder listed here that includes "homeassistant" in its devices is
      # offered to the add-on. With auto_accept_folders on in the add-on options
      # it is created there automatically under the configured folder root - no
      # Home Assistant side change needed to add a folder.
      folders = {
        notes = {
          path = "${config.home.homeDirectory}/Notes";
          devices = [ "homeassistant" ];
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "30";
          };
        };

        # Pull Home Assistant's own configuration onto this machine, read-only,
        # so an edit here can never break the instance.
        #   receiveonly: this side accepts changes but never sends them.
        # The matching add-on folder is declared in the add-on options with
        # path /homeassistant.
        # ha-config = {
        #   id = "ha-config";
        #   path = "${config.home.homeDirectory}/HomeAssistant";
        #   devices = [ "homeassistant" ];
        #   type = "receiveonly";
        # };
      };
    };
  };
}
