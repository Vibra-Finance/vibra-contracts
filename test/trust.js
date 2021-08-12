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
  this.deposit = async () => {
    // convenience method to increase allowance and send 5 tokens to smart contract from admin
    await vibra.increaseAllowance(trust.address, this.value, { from: admin });
    await trust.deposit(this.value, { from: admin });
  };

  beforeEach(async () => {
    vibra = await Vibra.new({ from: dev });
    trust = await Trust.new(
      vibra.address,
      beneficiary,
      organization,
      this.fees,
      { from: admin }
    );
    // mint 5 tokens to the admin address for testing
    await vibra.mint(admin, this.value, { from: dev });
  });

  it("Should have minted 5 tokens to the admin for testing", async () => {
    let balance = await vibra.balanceOf.call(admin);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should emit a Deposit event once the admin has deposited", async () => {
    await vibra.increaseAllowance(trust.address, this.value, { from: admin });
    let receipt = await trust.deposit(this.value, { from: admin });

    expectEvent(receipt, "Deposit", { _from: admin, _amount: this.value });
  });

  it("Should revert when admin has deposited less than the minimum amount", async () => {
    await vibra.increaseAllowance(trust.address, this.value, { from: admin });
    await expectRevert(
      trust.deposit(this.fees, { from: admin }),
      "Deposit must be greater than the min balance"
    );
  });

  it("Should deposit 5 tokens to the smart contract address", async () => {
    await this.deposit();
    let balance = await vibra.balanceOf.call(trust.address);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should revert when anybody other than the organization tries to charge fees", async () => {
    await this.deposit();
    await expectRevert(
      trust.chargeFees(this.fees, { from: beneficiary }),
      "Only the organization can call this function"
    );
  });

  it("Should charge fees to the smart contract", async () => {
    await this.deposit();
    await trust.chargeFees(this.fees, { from: organization });

    let balance = await vibra.balanceOf.call(organization);

    assert.equal(balance.toString(), this.fees.toString());
  });

  it("Should emit a Payment event once the fees have been payed to the organization", async () => {
    await this.deposit();
    let receipt = await trust.chargeFees(this.fees, { from: organization });

    expectEvent(receipt, "Payment", {
      _from: trust.address,
      _to: organization,
      _amount: this.fees,
    });
  });

  it("Should revert when somebody other than the admin tries to withdraw", async () => {
    await this.deposit();

    await expectRevert(
      trust.withdraw(this.fees, { from: organization }),
      "Only the admin can call this function"
    );
  });

  it("Should allow the admin to withdraw 1 token from the contract", async () => {
    await this.deposit();
    await trust.withdraw(this.fees, { from: admin });

    let balance = await vibra.balanceOf.call(admin);

    assert.equal(balance.toString(), this.fees.toString());
  });

  it("Should emit a Withdrawal event when the admin withdraws from contract", async () => {
    await this.deposit();
    let receipt = await trust.withdraw(this.fees, { from: admin });

    expectEvent(receipt, "Withdrawal", {
      _to: admin,
      _amount: this.fees,
    });
  });

  it("Should revert if anybody other than the admin tries to withdraw all", async () => {
    await this.deposit();

    await expectRevert(
      trust.withdrawAll({ from: organization }),
      "Only the admin can call this function"
    );
  });

  it("Should send 5 tokens back to admin after withdrawing all", async () => {
    await this.deposit();
    await trust.withdrawAll({ from: admin });

    let balance = await vibra.balanceOf.call(admin);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should emit a LowBalance event once the admin reaches minBalance", async () => {
    await this.deposit();
    let receipt = await trust.withdraw(new BN("4000000000000000000"), {
      from: admin,
    });

    expectEvent(receipt, "LowBalance", { _holder: admin, _balance: this.fees });
  });
});
