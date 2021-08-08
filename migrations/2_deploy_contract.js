const Vibra = artifacts.require("Vibra");
const Escrow = artifacts.require("Escrow");
const { BN } = require("@openzeppelin/test-helpers");

module.exports = async (deployer, _, accounts) => {
  await deployer.deploy(Vibra, { from: accounts[0] });
  await deployer.deploy(
    Escrow,
    Vibra.address,
    new BN("1"),
    accounts[1],
    accounts[2],
    { from: accounts[0] }
  );
};
