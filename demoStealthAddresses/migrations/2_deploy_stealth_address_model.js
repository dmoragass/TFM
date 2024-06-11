const DemoStealthAddresses = artifacts.require("DemoStealthAddresses");

module.exports = function (deployer) {
  deployer.deploy(DemoStealthAddresses);
};
