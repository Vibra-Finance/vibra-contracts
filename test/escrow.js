const { assert } = require("chai");
const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const Escrow = artifacts.require("Escrow");

contract("Escrow", async (accounts) => {
  let instance;
  const [admin, buyer, seller] = accounts;
  this.value = new BN(5);

  beforeEach(async () => {
    instance = await Escrow.new(this.value, buyer, seller, { from: admin });
  });

  it("Should have a state of Awaiting Payment once created", async () => {
    let status = await instance.state.call();

    assert.equal(status.toNumber(), 0);
  });

});
