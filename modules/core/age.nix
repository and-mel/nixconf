{ inputs, config, ... }:
{
  age.secrets.passwd-andrei.file = "${inputs.mysecrets}/passwd-andrei.age";
}
