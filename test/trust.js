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
  const [dev, admin, beneficiary, organization] = accounts;
  this.fees = new BN("1000000000000000000");
  this.value = new BN("5000000000000000000");

  beforeEach(async () => {
    vibra = await Vibra.new({ from: dev });
    trust = await Trust.new(
      vibra.address,
      beneficiary,
      organization,
      this.value,
      { from: admin }
    );

    await vibra.mint(admin, this.value, { from: dev });
  });

  it("Should have minted 5 tokens to the admin for testing", async () => {
    let balance = await vibra.balanceOf.call(admin);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should create new trust and deposit 5 tokens", async () => {
    await vibra.increaseAllowance(trust.address, this.value, { from: admin });
    await trust.deposit(this.value, { from: admin });

    let balance = await vibra.balanceOf.call(trust.address);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should emit a deposit event once the admin has deposited", async () => {
    await vibra.increaseAllowance(trust.address, this.value, { from: admin });
    let receipt = await trust.deposit(this.value, { from: admin });

    expectEvent(receipt, "Deposit", { _from: admin, _amount: this.value });
  });

  it("Should charge fees to the smart contract", async () => {
    await vibra.increaseAllowance(trust.address, this.value, { from: admin });
    await trust.deposit(this.value, { from: admin });
    await trust.chargeFees(this.fees, { from: organization });

    let balance = await vibra.balanceOf.call(organization);

    assert.equal(balance.toString(), this.fees.toString());
  });

});
