const Vibra = artifacts.require("Vibra");
const Escrow = artifacts.require("Escrow");
const { BN } = require("@openzeppelin/test-helpers");

module.exports = async (deployer, _, accounts) => {
  const [admin, buyer, seller] = accounts;
  await deployer.deploy(Vibra, { from: admin });
  const vibra = await Vibra.deployed();
  await deployer.deploy(Escrow, vibra.address, new BN("1"), buyer, seller, {
    from: admin,
  });
};
