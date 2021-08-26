const { BN } = require("@openzeppelin/test-helpers");
const Vibra = artifacts.require("Vibra");
const Escrow = artifacts.require("Escrow");
const Trust = artifacts.require("Trust");

module.exports = async (deployer, _, [admin, buyer, seller, parent, child]) => {
  await deployer.deploy(Vibra, { from: admin });
  const vibra = await Vibra.deployed();
  await deployer.deploy(Escrow, vibra.address, new BN("1"), buyer, seller, {
    from: admin,
  });
  await deployer.deploy(Trust, vibra.address, parent, child, new BN("1"), {
    from: admin,
  });
};
