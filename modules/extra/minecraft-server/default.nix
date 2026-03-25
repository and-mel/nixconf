# This config is no longer used, but it remains here for reference.

{
  pkgs,
  lib,
  config,
  user,
  ...
}:
let
  skyblockConfig =
    {
      name,
      port,
      gamemode ? 0,
      whitelist ? true,
    }:
    {
      enable = false;
      jvmOpts = "-Xms6144M -Xmx6144M";
      # Specify the custom minecraft server package
      package = pkgs.fabricServers.fabric-1_21_11.override {
        loaderVersion = "0.18.4";
      }; # Specific fabric loader version
      serverProperties = {
        online-mode = false;
        difficulty = 3;
        server-port = port;
        gamemode = gamemode;
        force-gamemode = true;
        motd = "open 5pm - 9pm";
        hide-online-players = true;
        enforce-secure-profile = false;
        view-distance = 48;
        white-list = whitelist;
      };
      whitelist = {
      };
      files = {
        mods = pkgs.linkFarmFromDrvs "mods" (
          builtins.attrValues {
            Fabric-API = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/i5tSkVBH/fabric-api-0.141.3%2B1.21.11.jar";
              sha256 = "sha256-hsRTqGE5Zi53VpfQOwynhn9Uc3SGjAyz49wG+Y2/7vU=";
            };
            Servux = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/zQhsx8KF/versions/wdbe92T5/servux-fabric-1.21.11-0.9.2.jar";
              sha256 = "sha256-UoxQj5VeDOemObqBJbI9DhBUcMBD05k8PfOU9xcTDOM=";
            };
            FabricProxy-Lite = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/nR8AIdvx/FabricProxy-Lite-2.11.0.jar";
              sha256 = "sha256-68er6vbAOsYZxwHrszLeaWbG2D7fq/AkNHIMj8PQPNw=";
            };
            LuckPerms = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/Vebnzrzj/versions/CzCJJMuo/LuckPerms-Fabric-5.5.21.jar";
              sha256 = "sha256-mNsvmLvat0o2x06LQuX18V5pkQUfSipV9N2rShDOEwQ=";
            };
            VanillaPermissions = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/fdZkP5Bb/versions/hA27RLKS/vanilla-permissions-0.3.3%2B1.21.11.jar";
              sha256 = "sha256-lfpy3NUHa1PYTJ0+zSxjeyzF87YZcOq0UXykc3yVQ4o=";
            };
            WorldEdit = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/1u6JkXh5/versions/o645q0Oo/worldedit-mod-7.4.0.jar";
              sha256 = "sha256-hk6xLxIpFkNFcUORnPv2haGvpiCmXC3LN3wvIRMqDrA=";
            };
            Carpet = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/TQTTVgYE/versions/HzPcczDK/fabric-carpet-1.21.11-1.4.194%2Bv251223.jar";
              sha256 = "sha256-G01m8DMr2l3u4IdV5JPC1qxk1k1SheETSqA2BJdcJSE=";
            };
            CarpetTISAddition = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/jE0SjGuf/versions/dW7vEXmE/carpet-tis-addition-v1.76.0-mc1.21.11.jar";
              sha256 = "sha256-iybMcnpSme26BtA9rn05orvZf85o9CTTOgX/f4E4Wvk=";
            };

          }
        );
        "config/FabricProxy-Lite.toml" = {
          value = {
            hackOnlineMode = false;
            hackEarlySend = true;
            hackMessageChain = true;
            disconnectMessage = "Velocity proxy error";
            secret = "gPzv8F0EAAlR";
          };
        };
        "config/luckperms/luckperms.conf" = pkgs.writeText "luckperms.conf" ''
          server = "${name}"
          storage-method = "mariadb"
          data {
            address = "127.0.0.1:3306"
            username = "minecraft"
            password = ""
            database = "minecraft"
          }
        '';
      };
    };

in
{
  options = {
    minecraft-server.enable = lib.mkEnableOption "enables Minecraft server";
    minecraft-server.ip = lib.mkOption {
      type = lib.types.str;
      description = "Minecraft server IP for port forwarding (DO NOT specify if you dont want port forwarding!)";
      default = "";
    };
  };

  config = lib.mkIf config.minecraft-server.enable {
    # services.minecraft-server = {
    #   enable = true;
    #   package = pinnedPkgs.minecraft-server;
    #   eula = true;
    #   jvmOpts = "-Xmx8192M -Xms8192M";
    #   openFirewall = true;
    # };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      settings = {
        mysqld = {
          bind-address = "127.0.0.1";
          port = 3306;
          max_connections = 100;
        };
      };
      ensureDatabases = [
        "minecraft"
      ];
      ensureUsers = [
        {
          name = "minecraft";
          ensurePermissions = {
            "minecraft.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    users.users.${user}.extraGroups = [ "minecraft" ];

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;
      servers.velocity =
        let
          plugins = {
            # ViaVersion = pkgs.fetchurl {
            #   url = "https://cdn.modrinth.com/data/P1OZGk5p/versions/zHujnINO/ViaVersion-5.7.2.jar";
            #   sha256 = "sha256-OI/MoCsKWJNtCSqd348reDi7XXzuV+IauzDgjb/r8mw=";
            # };
            NetworkJoinMessages = pkgs.fetchurl {
              url = "https://github.com/RagingTech/NetworkJoinMessages/releases/download/3.4.0/NetworkJoinMessages-3.4.0.jar";
              sha256 = "sha256-GHar3pM6BvKcGy3RFJv38c5vpH0xNSaCAGZ9gyMbDYI=";
            };
            LuckPerms = pkgs.fetchurl {
              url = "https://download.luckperms.net/1626/velocity/LuckPerms-Velocity-5.5.38.jar";
              sha256 = "sha256-/GIZBNBUdBC6ErzgftA4P+9cUP2IGpUvbRcjKbJ0EVc=";
            };
          };
        in
        {
          enable = true;
          jvmOpts = "-Xms1024M -Xmx1024M -Dvelocity.packet-decode-logging=true -Dvelocity.max-plugin-message-payload-size=2147483647 -Dvelocity.max-known-packs=512";
          package = pkgs.velocityServers.velocity;
          # files = {
          #   plugins = pkgs.runCommand "plugins" {} ''
          #     mkdir -p $out
          #     ${lib.concatStringsSep "\n" (
          #       lib.mapAttrsToList (name: drv:
          #         "ln -s ${drv} $out/${name}.jar"
          #       ) plugins
          #     )}
          #   '';
          # };
          files = {
            "plugins/networkjoinmessages/config.yml" = ./networkjoinmessages/config.yml;
          };
          symlinks = {
            "plugins/luckperms/config.yml" = pkgs.writeText "config.yml" ''
              server = "velocity"
              storage-method = "mariadb"
              data {
                address = "127.0.0.1:3306"
                username = "minecraft"
                password = ""
                database = "minecraft"
              }
            '';
            "plugins/bStats/config.txt" = pkgs.writeText "config.txt" ''
              enabled=false
              server-uuid=37d1f9fd-cfeb-4f2c-90a0-b994672de0c5
              log-errors=false
              log-sent-data=false
              log-response-status-text=false
            '';
            "plugins/viaversion/config.yml" = ./viaversion/config.yml;
            "velocity.toml" = {
              value = {
                advanced = {
                  accepts-transfers = false;
                  announce-proxy-commands = true;
                  bungee-plugin-message-channel = true;
                  command-rate-limit = 50;
                  compression-level = -1;
                  compression-threshold = 256;
                  connection-timeout = 5000;
                  enable-reuse-port = false;
                  failover-on-unexpected-server-disconnect = true;
                  forward-commands-if-rate-limited = true;
                  haproxy-protocol = false;
                  kick-after-rate-limited-commands = 0;
                  kick-after-rate-limited-tab-completes = 0;
                  log-command-executions = false;
                  log-player-connections = true;
                  login-ratelimit = 3000;
                  read-timeout = 30000;
                  show-ping-requests = false;
                  tab-complete-rate-limit = 10;
                  tcp-fast-open = false;
                };
                announce-forge = false;
                bind = "0.0.0.0:25565";
                config-version = "2.7";
                enable-player-address-logging = true;
                force-key-authentication = false;
                forced-hosts = { };
                forwarding-secret-file = "forwarding.secret";
                kick-existing-players = false;
                motd = "<#09add3>A Velocity Server";
                online-mode = true;
                ping-passthrough = "DISABLED";
                player-info-forwarding-mode = "modern";
                prevent-client-proxy-connections = false;
                query = {
                  enabled = false;
                  port = 25565;
                  map = "Velocity";
                  show-plugins = false;
                };
                sample-players-in-ping = false;
                servers = {
                  skyblock-survival = "127.0.0.1:25570";
                  skyblock-creative = "127.0.0.1:25571";
                  survival = "127.0.0.1:25572";

                  try = [
                    "survival"
                    "skyblock-creative"
                  ];
                };
                show-max-players = 500;
              };
            };
            "forwarding.secret" = pkgs.writeText "forwarding.secret" "gPzv8F0EAAlR";
            # "plugins/bStats/config.yml" = pkgs.writeText "config.yml" "enabled: false";
          }
          // lib.mapAttrs' (name: drv: {
            name = "plugins/${name}.jar";
            value = drv;
          }) plugins;
        };
      servers.skyblock-survival = skyblockConfig {
        name = "skyblock-survival";
        port = 25570;
        gamemode = 0;
      };
      servers.skyblock-creative =
        skyblockConfig {
          name = "skyblock-creative";
          port = 25571;
          gamemode = 1;
          whitelist = false;
        }
        // {
          enable = true;
        };
      servers.survival = {
        enable = true;
        jvmOpts = "-Xms24576M -Xmx24576M";
        # Specify the custom minecraft server package
        package = pkgs.fabricServers.fabric-1_21_8.override {
          loaderVersion = "0.18.4";
        }; # Specific fabric loader version
        serverProperties = {
          online-mode = true;
          difficulty = 3;
          server-port = 25572;
          gamemode = 0;
          force-gamemode = true;
          motd = "open 5pm - 9pm";
          hide-online-players = true;
          enforce-secure-profile = false;
          view-distance = 16;
          white-list = true;
          level-type = "bigglobe:bigglobe";
        };
        whitelist = { };
        files = {
          mods = pkgs.linkFarmFromDrvs "mods" (
            builtins.attrValues {
              Fabric-API = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/g58ofrov/fabric-api-0.136.1%2B1.21.8.jar";
                sha256 = "sha256-JMLJx/oflpmC3fFCpfF7NWuIpescsezpwoeliPNFEjM=";
              };
              FabricProxy-Lite = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/KqB3UA0q/FabricProxy-Lite-2.10.1.jar";
                sha256 = "sha256-NnN7Ysel37Z5rD+san2xD5pCMxf7oZV0vE1HK0cRx0I=";
              };
              FerriteCore = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/uXXizFIs/versions/LdlksamY/ferritecore-8.0.4-fabric.jar";
                sha256 = "sha256-K/d6ISjM7uURH7OY2m20rxrDjmT+f3ZqqNfbRdPWhms=";
              };
              Lithium = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/qxIL7Kb8/lithium-fabric-0.18.1%2Bmc1.21.8.jar";
                sha256 = "sha256-BPNwwvboGdzYajxWhOOP0enEmIx8JJP/srwH60UEuUw=";
              };
              C2ME = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/VSNURh3q/versions/tlZRTK1v/c2me-fabric-mc1.21.8-0.3.4.0.0.jar";
                sha256 = "sha256-MkYZOI9AL7yswqEfSp8/Njs4z7xFRItuvLu96znO/v4=";
              };
              Big-Globe = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/xsng1aJf/versions/GJwF59jS/Big%20Globe-5.2.0-MC1.21.8.jar";
                sha256 = "sha256-2DHqsQHd7ZmeLuQtxk3RBCSSt21AUN+/Sf0fIQc9+q4=";
              };
              Structure-Layout-Optimizer = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/ayPU0OHc/versions/qvfSaFES/structure_layout_optimizer-1.1.4%2B1.21.6-fabric.jar";
                sha256 = "sha256-v4CiW1StmrH45QzfYO2dlxOanCmgwcimT0R6L6tpGuw=";
              };
              Vertigo = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/4LzgJp1j/versions/FkMPdaXL/Vertigo-1.1.7-MC1.21.8.jar";
                sha256 = "sha256-FhieGXfltgCt6W4ABK40Dx1WU4gzfJKv067UwCktNJ4=";
              };
              Distant-Horizons = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/uCdwusMi/versions/PWWYVdOA/DistantHorizons-2.4.5-b-1.21.8-fabric-neoforge.jar";
                sha256 = "sha256-gLK9GXaOyLAZRwHpfr5XlM2zhMjkw/FhSiLEb4HoWYM=";
              };
              ScalableLux = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/Ps1zyz6x/versions/Bi5i8Ema/ScalableLux-0.1.5.1%2Bfabric.abdeefa-all.jar";
                sha256 = "sha256-0tnpTeuoFTPVPnOzRfUsjZkLdUY0XVD6t+IHJo9JV88=";
              };
              Resourceful-Config = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/M1953qlQ/versions/YwwLmDz9/ResourcefulConfig-fabric-1.21.7-3.7.6.jar";
                sha256 = "sha256-QN+o8+Z7qhKF7FjS9fIr8GggPkmz7AaFrYUlMIyso04=";
              };
              CrossStitch = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/YkOyn1Pn/versions/8h1nxay1/crossstitch-0.1.7.jar";
                sha256 = "sha256-tmyCijs1xWRYiXt68xE+bSJdk464mYuTYVAdVKK1dO4=";
              };
              Chunky = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/fALzjamp/versions/inWDi2cf/Chunky-Fabric-1.4.40.jar";
                sha256 = "sha256-TdVDDtm0K/t+TtEKPsBN7gjGv1dJO6hydpo6jvEKcMI=";
              };
              REI = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/nfn13YXA/versions/hoEFy7aF/RoughlyEnoughItems-20.0.811-fabric.jar";
                sha256 = "sha256-e2t1DkKcRCCF+gdFsDwnOyQiTxzngF2DnrUqmfKwJTo=";
              };
              Architectury = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/XcJm5LH4/architectury-17.0.8-fabric.jar";
                sha256 = "sha256-tdBR+O/+j5R2+TdeEeSN+vuCF5FDW4/jaIaZADl/BdU=";
              };
              Cloth-Config-API = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/9s6osm5g/versions/cz0b1j8R/cloth-config-19.0.147-fabric.jar";
                sha256 = "sha256-2KbcqdDa0f5EYio8agNIZBk045Q8jUJaJvESvObev6I=";
              };
              # XXL-Packets = pkgs.fetchurl {
              #   url = "https://cdn.modrinth.com/data/SeCuopwJ/versions/fllia1S2/xlpackets-1.0.5-1.21.jar";
              #   sha256 = "sha256-q7FuvbLyPqJClHUeiQ4iYEWZtrLIaoPHoKKkHUR3PDc=";
              # };
            }
          );
          "config/FabricProxy-Lite.toml" = {
            value = {
              hackOnlineMode = true;
              hackEarlySend = true;
              hackMessageChain = true;
              disconnectMessage = "Velocity proxy error";
              secret = "gPzv8F0EAAlR";
            };
          };
          "config/DistantHorizons.toml" = pkgs.writeText "DistantHorizons.toml" ''

          '';
          "config/luckperms/luckperms.conf" = pkgs.writeText "luckperms.conf" ''
            server = "survival"
            storage-method = "mariadb"
            data {
              address = "127.0.0.1:3306"
              username = "minecraft"
              password = ""
              database = "minecraft"
            }
          '';
          "config/bigglobe/mixins.properties" = pkgs.writeText "mixins.properties" ''
            #Sun Mar 22 12:31:00 EDT 2026
            builderb0y.bigglobe.mixins.AzaleaBlock_GrowIntoBigGlobeTree=true
            builderb0y.bigglobe.mixins.BackgroundRenderer_NoFogWithLods=true
            builderb0y.bigglobe.mixins.BackgroundRenderer_SoulLavaFogColor=true
            builderb0y.bigglobe.mixins.BiomeColors_UseNoiseInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.Biome_DontFreezeRiverWater=true
            builderb0y.bigglobe.mixins.BoneMealItem_SpreadChorusNylium=true
            builderb0y.bigglobe.mixins.BubbleColumnBlock_WorkWithSoulMagma=true
            builderb0y.bigglobe.mixins.Camera_HandleSoulLavaSubmersion=true
            builderb0y.bigglobe.mixins.CatEntity_PetTheKitty=false
            builderb0y.bigglobe.mixins.ChorusFlowerBlock_AllowPlacementOnOtherTypesOfEndStones=true
            builderb0y.bigglobe.mixins.ChorusPlantBlock_AllowPlacementOnOtherTypesOfEndStones=true
            builderb0y.bigglobe.mixins.ChorusPlantFeature_AllowPlacementOnOtherTypesOfEndStones=true
            builderb0y.bigglobe.mixins.Chunk_NotifyLodSystem=true
            builderb0y.bigglobe.mixins.ClientWorldProperties_SetHorizonHeightToSeaLevel=true
            builderb0y.bigglobe.mixins.ClientWorld_CustomTimeSpeed=true
            builderb0y.bigglobe.mixins.CreakingHeartBlockEntity_MakeWorkInTheNether=true
            builderb0y.bigglobe.mixins.CreakingHeartBlock_MakeWorkInTheNether=true
            builderb0y.bigglobe.mixins.CreateWorldScreen_MakeBigGlobeTheDefaultWorldType=true
            builderb0y.bigglobe.mixins.CreateWorldScreen_MakeBigGlobeTheDefaultWorldType$WorldTab_HandleUnknownWorldTypesSanely=true
            builderb0y.bigglobe.mixins.DebugHud_ShowLodStatus=true
            builderb0y.bigglobe.mixins.Dev_CreateWorldScreen_DontCrashOnFailure=false
            builderb0y.bigglobe.mixins.Dev_NbtCompound_SanityCheckValues=true
            builderb0y.bigglobe.mixins.Dev_ServerPlayNetworkHandler_StopGeneratingChunksForSpectators=false
            builderb0y.bigglobe.mixins.DimensionOptions_CheckHeights=false
            builderb0y.bigglobe.mixins.EndCityStructure_UnHardcodeMinimumY=true
            builderb0y.bigglobe.mixins.EndGatewayBlockEntity_UseAlternateLogicInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.EndPortalBlock_SpawnAtPreferredLocationInTheEnd=true
            builderb0y.bigglobe.mixins.EnderDragonFight_SpawnGatewaysAtPreferredLocation=true
            builderb0y.bigglobe.mixins.EnderDragonSpawnState_UseBigGlobeEndSpikesInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.EnderPearlEntity_ReduceFallDamageWithVoidmetalArmor=true
            builderb0y.bigglobe.mixins.Entity_SpawnAtPreferredLocationInTheEnd=true
            builderb0y.bigglobe.mixins.EyeblossomBlock_MakeWorkInTheNether=true
            builderb0y.bigglobe.mixins.FlowableFluid_DontFlowInRivers=true
            builderb0y.bigglobe.mixins.FluidRenderer_DontHardCodeChunkSectionSizedAreas=true
            builderb0y.bigglobe.mixins.FungusBlock_GrowIntoBigGlobeTree=true
            builderb0y.bigglobe.mixins.GameRenderer_CaptureProjectionMatrix=true
            builderb0y.bigglobe.mixins.GrassBlock_UseCustomFeatureInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.HuskEntity_AllowSpawningUndergroundInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.IglooGeneratorPiece_DontMoveInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.ImmersivePortals_NetherPortalMatcher_PlacePortalHigherInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.Items_PlaceableFlint=true
            builderb0y.bigglobe.mixins.Items_PlaceableSticks=true
            builderb0y.bigglobe.mixins.MinecraftClient_LoadingFinishedHook=true
            builderb0y.bigglobe.mixins.MinecraftServer_InitializeSpawnPoint=true
            builderb0y.bigglobe.mixins.MinecraftServer_LoadSmallerSpawnArea=false
            builderb0y.bigglobe.mixins.MobSpawnerLogic_SpawnLightning=true
            builderb0y.bigglobe.mixins.NetherrackBlock_GrowProperly=true
            builderb0y.bigglobe.mixins.OceanMonumentGeneratorBase_VanillaBugFixes=true
            builderb0y.bigglobe.mixins.OceanMonumentStructure_MovePiecesOnReCreate=true
            builderb0y.bigglobe.mixins.OceanMonumentStructure_UseCorrectPosition=true
            builderb0y.bigglobe.mixins.OceanRuinGeneratorPiece_UseGeneratorHeight=true
            builderb0y.bigglobe.mixins.PlayerEntity_FlyInHyperspace=true
            builderb0y.bigglobe.mixins.PlayerManager_InitializeSpawnPoint=true
            builderb0y.bigglobe.mixins.PlayerManager_SyncWorldSettingsHook=true
            builderb0y.bigglobe.mixins.PortalForcer_PlaceInNetherCaverns=true
            builderb0y.bigglobe.mixins.RailBlock_RotateProperly=true
            builderb0y.bigglobe.mixins.SaplingBlock_GrowIntoBigGlobeTree=true
            builderb0y.bigglobe.mixins.ServerPlayerEntity_CreateEndSpawnPlatformOnlyIfPreferred=true
            builderb0y.bigglobe.mixins.ServerWorld_CustomTimeSpeed=true
            builderb0y.bigglobe.mixins.ServerWorld_SpawnEnderDragonInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.ShipwreckGeneratorPiece_UseGeneratorHeight=true
            builderb0y.bigglobe.mixins.SlimeEntity_AllowSpawningFromSpawner=true
            builderb0y.bigglobe.mixins.Sodium_WorldSlice_UseNoiseInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.SpawnHelper_AllowSlimeSpawningInLakes=true
            builderb0y.bigglobe.mixins.SpawnHelper_MoreMobsInTallerWorlds=false
            builderb0y.bigglobe.mixins.StairsBlock_MirrorProperly=true
            builderb0y.bigglobe.mixins.StructureAccessor_UseStructureManagerInBigGlobeWorlds=true
            builderb0y.bigglobe.mixins.SugarCaneBlock_MakePlaceableOnGravel=true
            builderb0y.bigglobe.mixins.TagGroupLoader_DontLoadMyF___ingTags=true
            builderb0y.bigglobe.mixins.ThrownEntity_CollisionHook=true
            builderb0y.bigglobe.mixins.VoxyIntegration=true
            builderb0y.bigglobe.mixins.WoodlandMansionStructure_DontHardCodeSeaLevel=true
            builderb0y.bigglobe.mixins.WorldGenProperties_LogLevelType=true
            builderb0y.bigglobe.mixins.WorldPresets_MakeBigGlobeTheDefaultWorldType2=true
            builderb0y.bigglobe.mixins.WorldRenderer_RenderHyperspaceSky=true
            builderb0y.bigglobe.mixins.WorldType_ChangeTranslation=true
            builderb0y.bigglobe.mixins.World_UseCorrectSeaLevel=true
          '';
          "config/bigglobe/Big Globe.json5" = pkgs.writeText "Big Globe.json5" ''
            {

             	//Controls the world type which is selected by default when creating a world.
             	//If the provided world type is malformed or unknown to the game, minecraft:normal will be used instead.
             	//This config option can be useful if you like to create lots of worlds of the same type, or you're making a modpack.
             	"Default World Type": "bigglobe:bigglobe",

             	//If true, Big Globe will sanity check that the height of each dimension matches that of the chunk generator assigned to that dimension.
             	//If false, Big Globe will assume that any discrepancies are intentional.
             	//This config option only applies to dimensions with scripted chunk generators because some vanilla dimensions fail this check. This check can be useful for finding broken data packs or mods that modify the world height in unsafe ways, and can even prevent world corruption.
             	"Sanity Check World Height": true,

             	//If true, saplings will grow into Big Globe trees in Big Globe worlds.
             	//If false, saplings will grow into normal (vanilla) trees in Big Globe worlds.
             	//This config option has no effect on trees that spawn during worldgen.
             	"Big Globe Trees In Big Globe Worlds": true,

             	//If true, waypoints will be usable.
             	//If false, waypoints cannot be used.
             	//The hyperspace dimension is a fast travel mechanic which allows players to quickly visit places they've been to before. This config option is provided for players who don't like fast travel or prefer a different mod's teleportation mechanics.
             	"Hyperspace Enabled": true,

             	//Global multiplier for how much ore you get from pouring water on molten rock.
             	//If this is set to 0, you will only get stone from this process.
             	//Molten rock can be found in the core at the bottom of the world. It is very difficult to get to, and very rewarding for the resources it grants. Nevertheless, this config option exists for people who think this system is overpowered.
             	"Molten Rock Ore-ification Chance": 1.0,

             	//Number of threads to use for worldgen tasks (including worldgen for Distant Horizons and Voxy)
             	//More threads will result in faster terrain gen, but may reduce performance in other areas of the game.
             	//Less threads will result in slower terrain gen, but may improve performance in other areas of the game.
             	"Threads": 8,

             	//Configures how initial player spawning works in Big Globe worlds.
             	//These config options have no effect outside of Big Globe worlds.
             	"Player Spawning": {

              		//Maximum distance from the origin which players can spawn at.
              		//This is a square distance, not a circular distance.
              		"Max Spawn Radius": 10000.0,

              		//If true, every player will be given their own unique spawn point the first time they spawn in the world.
              		//If false, every player will spawn at the world's spawn point.
              		//This config option does not affect players who have set their spawn point manually with a bed, a respawn anchor, or the /spawnpoint command.
              		"Per-Player Spawn Points": false
             	},

             	//Options that are useful for data pack developers.
             	//Normal users should leave all of these disabled.
             	"Data Pack Debugging": {

              		//If true, Big Globe will generate graphs showing all column value dependencies.
              		//If false, Big Globe will not do that.
              		//The generated graphs can sometimes be useful for finding unexpected or accidental dependencies.
              		"Generate dependency graphs": false,

              		//If true, Big Globe will print all decision trees to the game console and log file when they're loaded.
              		//If false, Big Globe will not do that.
              		//Decision trees can be hard to follow, so having the entire tree in one place can be useful for understanding its structure.
              		"Print decision trees": false,

              		//If true, Big Globe will log a message to the game console and log file when a structure attempts to spawn somewhere and, if applicable, the reason why it failed to spawn there.
              		//If false, Big Globe will not do that.
              		//This option can be useful for debugging why a specific structure isn't spawning anywhere.
              		"Log structure spawn attempts": false,

              		//If true, Big Globe will log a message to the game console and log file when an empty tag is loaded.
              		//If false, Big Globe will not do that.
              		//This option can be useful for finding tags that you forgot to put values in, and can occasionally be useful for debugging tags that are referenced before loading is complete, resulting in a tag that shouldn't be empty, but is.
              		"Log empty tags": false,

              		//If true, Big Globe will prevent the world from loading if overriders are found which are not in any tags.
              		//If false, Big Globe will log a warning in this case instead.
              		//This option can be useful as a sanity check to ensure your overrider tags are setup correctly.
              		"Reject unused overriders": false,

              		//VANILLA: Use vanilla logic. (pretends the tag is empty if it contains any invalid entries)
              		//FORCE_LOAD: Same as the "Load My F***ing Tags" mod. (loads all valid entries and ignores invalid entries)
              		//FORCE_ABORT: Fails datapack validation if any tags contain invalid entries. Useful for finding errors in data packs.
              		//Due to mixin conflicts, this option is ignored when using forge via Sinytra Connector, and vanilla logic is always used there.
              		"Invalid tag handling": "VANILLA",

              		//If true, Big Globe will log a message to the game console and log file when extra mob spawns are computed for a biome/spawn group.
              		//If false, Big Globe will not do that.
              		//Extra mob spawns are computed lazily and as-needed, so not all spawns will be printed immediately when the world is loaded.
              		"Log extra mob spawns": false
             	},

             	//Configures Big Globe's native LOD rendering functionality.
             	//LOD rendering lets you see farther without significant framerate drops.
             	"LOD Rendering": {

              		//ON: Big Globe will generate and render a simplified model of the world that has a very far view distance, but lacks things like structures and features.
              		//OFF: Big Globe will not do that.
              		//AUTO: Big Globe will only do that when neither Distant Horizons nor Voxy are installed.
              		//If you're on multiplayer, the server and the client must both have this option enabled for LOD rendering to work.
              		"Enabled": "AUTO",

              		//This config option controls what openGL tricks Big Globe uses to render LODs.
              		//It is recommended to set this to AUTO to allow Big Globe to pick the best backend for your hardware and drivers.
              		//This option exists for people who have compatibility issues with Big Globe's default selection.
              		//SIMPLE_SEPARATE: uses one glDrawElements() call for each LOD node.
              		//SIDED_SEPARATE: groups faces by normal vector, and for each LOD node, issues a glMultiDrawElements() call for all faces which are facing towards the player.
              		//SIDED_COMBINED: groups faces by normal vector, and at the end of rendering, issues a single glMultiDrawElements() call for all visible geometry.
              		//AUTO: uses SIDED_COMBINED if GL_ARB_shader_draw_parameters is available, and SIDED_SEPARATE otherwise.
              		"Renderer Backend": "AUTO",

              		//The number of quads Big Globe will allow itself to render.
              		//More quads will allow higher quality LOD rendering with less frequent lag spikes.
              		//Fewer quads will use less VRAM.
              		"Maximum Quad Count": 50000000,

              		//Factor controlling how far away LOD terrain can render before it gets replaced with a lower quality version of that terrain.
              		//Higher quality will use higher quality models for further distances.
              		//Lower quality will reduce time between lag spikes.
              		"Quality": 2.0,

              		//Higher numbers will result in non-worldgen blocks rendering from farther away.
              		//Lower numbers will result in better performance, as chunk loading is slow, and so is rendering caves unnecessarily.
              		//LOD chunk loading currently only works in singleplayer.
              		"Max LOD For Chunk Loading": 5,

              		//Maximum number of solid blocks which can be skipped over when constructing LOD geometry from real blocks.
              		//Higher numbers will result in less memory usage.
              		//Lower numbers will result in more accurate LODs.
              		"Vertical Compression": 16,

              		//Depth below the surface where real blocks start getting ignored.
              		//Higher numbers will allow some caves near the surface to continue rendering in LODs.
              		//Set to -1 to disable cave culling and allow all caves to render.
              		"Cave Culling Depth": 16,

              		//Closest distance that LOD terrain will render at, as a multiplier of your vanilla render distance.
              		//Lower numbers will allow LOD terrain to render closer to the player.
              		//Visual artifacts may occur if this number is too small. Must be greater than 0 and less than Max View Distance.
              		"Min View Distance": 0.25,

              		//Furthest distance that LOD terrain will render at, as a multiplier of your vanilla render distance.
              		//Higher numbers will allow LOD terrain to render further away from the player.
              		//Visual artifacts may occur if this number is too large. Must be greater than Min View Distance.
              		"Max View Distance": 1024.0,

              		//Distance where Big Globe will generate LOD terrain inside, as a multiplier of your vanilla render distance.
              		//Higher numbers can reduce flickering LODs when moving quickly, but will also place higher demands on VRAM usage.
              		//Must be greater than or equal to Max View Distance.
              		"Generation Buffer Distance": 1536.0,

              		//Multiplier for the amount of fog on LODs. Note that normal terrain does not have fog when LOD rendering is enabled.
              		//Higher numbers mean more fog.
              		//Setting this to 0 will disable fog for LODs.
              		"Fog Density": 64.0,

              		//How much the fog density depends on Y level.
              		//Higher numbers mean more fog at lower Y levels and less fog at higher Y levels.
              		//Setting this to 0 will mean the fog density is uniform. In other words, the fog shape will be spherical.
              		"Fog Height Scale": 4.0,

              		//NONE - The underground and all blocks in it are completely skipped.
              		//FILL - The underground will be filled with stone, but no caves will generate.
              		//CARVE - Caves will generate, but underground structures and features will not.
              		//DECORATE - All underground stuff will generate normally.
              		//Reducing this value can increase the speed which Big Globe can generate LOD terrain at.
              		"Underground Mode": "FILL"
             	},

             	//Configures special actions to skip when generating chunks for Distant Horizons.
             	//None of these actions will ever be skipped for normal chunks. This category will have no effect if Distant Horizons is not installed.
             	"Distant Horizons Integration": {

              		//If true, Big Globe will generate distant terrain directly through Distant Horizons' API, skipping chunks entirely.
              		//If false, Big Globe will allow Distant Horizons to wrap Big Globe's default chunk generator.
              		//Enabling this config option will skip structures and features. In particular, you will not see any trees with this option enabled until you get close to them.
              		"Hyperspeed Generation": false,

              		//NONE - The underground and all blocks in it are completely skipped.
              		//FILL - The underground will be filled with stone, but no caves will generate.
              		//CARVE - Caves will generate, but underground structures and features will not.
              		//DECORATE - All underground stuff will generate normally.
              		//Reducing this value can increase the speed which Big Globe can generate chunks for Distant Horizons at.
              		"Underground Mode": "FILL"
             	},

             	//Configures special actions to take or skip when generating chunks for Voxy.
             	//None of these actions will ever be skipped for normal chunks. This category will have no effect if Voxy is not installed.
             	"Voxy Integration": {

              		//If true, Big Globe will generate terrain for Voxy constantly in a background thread.
              		//If false, Voxy will only process chunks you've visited.
              		//Note that terrain generated this way may be a simplified representation of actual terrain, and finer details may be filled in only when you get closer to it.
              		"Use Worldgen Thread": true,

              		//NONE - The underground and all blocks in it are completely skipped.
              		//FILL - The underground will be filled with stone, but no caves will generate.
              		//CARVE - Caves will generate, but underground structures and features will not.
              		//DECORATE - Currently the same as 2, but maybe some day underground structures and features might generate too.
              		//Reducing this value can increase the speed which Big Globe can generate chunks for Voxy at.
              		"Underground Mode": "NONE",

              		//If true, Big Globe will tell Voxy what the light level of air blocks are.
              		//If false, Big Globe will skip air blocks when giving data to Voxy.
              		//Enabling this option can fix some lighting errors with Voxy, at the cost of LOD generation speed.
              		"Light Air": false
             	},

             	//Configures special behaviors when C2ME is installed.
             	//These options are ignored when C2ME is not installed.
             	"C2ME Integration": {

              		//If true, Big Globe will use multiple threads when generating structures.
              		//If false, Big Globe will use a single thread when generating structures.
              		//This config option can be disabled if it causes instability.
              		"Multi-Threaded Structures": true
             	},

             	//Don't change this.
             	"Config Version": 1
            }
          '';
        };
      };
    };

    # environment.systemPackages = with pkgs; [
    #   miniupnpc
    # ];

    # systemd.services.open-upnp-port = lib.mkIf (config.minecraft-server.ip != "") {
    #   script = ''
    #     ${lib.getExe pkgs.miniupnpc} -a ${config.minecraft-server.ip} 25565 25565 tcp
    #   '';

    #   # This service runs once and finishes,
    #   # instead of the default long-live services
    #   serviceConfig = {
    #     Type = "oneshot";
    #   };

    #   # "Enable" the service
    #   wantedBy = [ "multi-user.target" ];
    # };
  };
}
