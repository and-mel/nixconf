{ inputs, ... }:
{
  age.secrets.passwd-andrei.file = "${inputs.mysecrets}/passwd-andrei.age";
  age.secrets.passwd-ds2.file = "${inputs.mysecrets}/passwd-ds2.age";
  age.secrets.wg-privatekey.file = "${inputs.mysecrets}/wg-privatekey.age";
  age.secrets.xray-privatekey.file = "${inputs.mysecrets}/xray-privatekey.age";
  age.secrets.acme-env.file = "${inputs.mysecrets}/acme-env.age";
}
