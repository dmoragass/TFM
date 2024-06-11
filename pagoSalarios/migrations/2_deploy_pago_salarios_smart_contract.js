const PagoSalarios = artifacts.require("PagoSalarios");

module.exports = function (deployer) {
  deployer.deploy(PagoSalarios);
};
