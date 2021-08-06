const Vibra = artifacts.require("Vibra");
const Escrow = artifacts.require("Escrow");
const { BN } = require("@openzeppelin/test-helpers");

module.exports = async (deployer, _, accounts) => {
  let vibra = await deployer.deploy(Vibra, { from: accounts[0] });
  let escrow = await deployer.deploy(
    Escrow,
    new BN(5),
    accounts[1],
    accounts[2],
    { from: accounts[0] }
  );
};
