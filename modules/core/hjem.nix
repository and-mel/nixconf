{
  inputs,
  lib,
  pkgs,
  user,
  ...
}:
{
  hjem.users.${user} = {
    enable = true;
  };
}
