const { assert } = require("chai");
const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const Trust = artifacts.require("Trust");
const Vibra = artifacts.require("Vibra");

contract("Trust", async (accounts) => {
  let trust, vibra;
  const [admin, beneficiary, organization] = accounts;

  beforeEach(async () => {
    vibra = await Vibra.new({ from: admin });
    trust = await Trust.new(vibra.address, { from: admin });
  });
});
