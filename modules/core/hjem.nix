{ inputs, lib, pkgs, user, ... }:
{
  hjem.users.${user} = {
    enable = true;
    files = {
      ".ssh/config".text = ''
        Host github.com
          User git
          IdentityFile ~/.ssh/id_ed25519_sk
          IdentitiesOnly yes
      '';
    };
  };
}
