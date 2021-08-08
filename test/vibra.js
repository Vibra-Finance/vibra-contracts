const { assert } = require("chai");
const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const Vibra = artifacts.require("Vibra");

contract("Vibra", async (accounts) => {
  let instance;
  const [admin, smartContract, reciever] = accounts;
  this.value = new BN("5000000000000000000");
  this.totalSupply = new BN("100000000000000000000000000");

  beforeEach(async () => {
    instance = await Vibra.new({ from: admin });
  });

  it("Should create new token and mint 100M tokens", async () => {
    let totalSupply = await instance.totalSupply.call();

    assert.equal(totalSupply.toString(), this.totalSupply.toString());
  });

  it("Should send 100M tokens to the admin address", async () => {
    let balance = await instance.balanceOf.call(admin);

    assert.equal(balance.toString(), this.totalSupply.toString());
  });

  it("Should send 5 tokens to the designated smart contract address", async () => {
    await instance.transferFrom(admin, smartContract, this.value);

    let balance = await instance.balanceOf(smartContract);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should approve the smart contract to spend 5 tokens", async () => {
    let receipt = await instance.increaseAllowance(smartContract, this.value);

    expectEvent(receipt, "Approval", {
      owner: admin,
      spender: smartContract,
      value: this.value,
    });
  });
});
