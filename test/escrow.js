const { assert } = require("chai");
const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const Escrow = artifacts.require("Escrow");
const Vibra = artifacts.require("Vibra");

contract("Escrow", async (accounts) => {
  let escrow, vibra;
  const [admin, buyer, seller] = accounts;
  this.temp = new BN("2000000000000000000");
  this.value = new BN("5000000000000000000");
  this.deposit = async () => {
    await vibra.increaseAllowance(escrow.address, this.value, { from: buyer });
    return await escrow.deposit(this.value, { from: buyer });
  };

  beforeEach(async () => {
    vibra = await Vibra.new({ from: admin });
    escrow = await Escrow.new(vibra.address, this.value, buyer, seller, {
      from: admin,
    });
    // mint 5 tokens to the buyer address for testing purposes
    await vibra.mint(buyer, this.value, { from: admin });
  });

  it("Should have minted 5 tokens to the buyer for testing", async () => {
    let balance = await vibra.balanceOf.call(buyer);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should have a state of Awaiting Payment once created", async () => {
    let status = await escrow.state.call();

    assert.equal(status.toNumber(), 0);
  });

  it("Should revert when buyer deposits incorrect amount", async () => {
    await vibra.increaseAllowance(escrow.address, this.value, { from: buyer });

    await expectRevert(
      escrow.deposit(this.temp, { from: buyer }),
      "Incorrect deposit amount"
    );
  });

  it("Should increase the contracts allowance to 5 tokens", async () => {
    await vibra.increaseAllowance(escrow.address, this.value, { from: buyer });

    let allowance = await vibra.allowance(buyer, escrow.address);

    assert.equal(allowance.toString(), this.value.toString());
  });

  it("Should have a state of Awaiting Delivery once deposit is made", async () => {
    await this.deposit();

    let status = await escrow.state.call();

    assert.equal(status.toNumber(), 1);
  });

  it("Should emit a Deposit event once a user makes a deposit", async () => {
    let receipt = await this.deposit();

    expectEvent(receipt, "Deposit", { _from: buyer, _value: this.value });
  });

  it("Should have a balance of 5 tokens once the buyer has deposited", async () => {
    await this.deposit();

    let balance = await vibra.balanceOf.call(escrow.address);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should send 5 tokens to the seller from the smart contract, leaving an escrow balance of 0", async () => {
    await this.deposit();
    await escrow.confirmDelivery({ from: buyer });

    let balance = await vibra.balanceOf.call(escrow.address);

    assert.equal(balance.toString(), "0");
  });

  it("Should emit a Payment event when delivery is confirmed", async () => {
    await this.deposit();
    let receipt = await escrow.confirmDelivery({ from: buyer });

    expectEvent(receipt, "Payment", { _to: seller, _value: this.value });
  });


  it("Should set escrow state to COMPLETE (4)", async () => {
    await this.deposit();
    await escrow.confirmDelivery({ from: buyer });

    let state = await escrow.state.call();

    assert.equal(state.toString(), "4");
  });

  it("Should send 5 tokens to the seller from the smart contract, giving the seller a balance of 5", async () => {
    await this.deposit();
    await escrow.confirmDelivery({ from: buyer });

    let balance = await vibra.balanceOf.call(seller);

    assert.equal(balance.toString(), this.value.toString());
  });

  it("Should revert if anybody other than the buyer tries to dispute", async () => {
    await this.deposit();

    await expectRevert(
      escrow.dispute({ from: admin }),
      "Only the buyer can call this function"
    );
  });
  
  it("Should revert when the contract is in the incorrect state", async () => {
    await this.deposit();

    // skipping dispute call so contract is still in AWAITING DELIVERY STATE
    await expectRevert(
      escrow.processRefund({ from: admin }),
      "Must be in disputed state"
    );
  });

  it("Should emit a Refund event when a refund is processed", async () => {
    await this.deposit();
    await escrow.dispute({ from: buyer });

    let receipt = await escrow.processRefund({ from: admin });

    expectEvent(receipt, "Refund", { _to: buyer, _value: this.value });
  });

  it("Should send 5 tokens back to the buyer after a refund is processed", async () => {});
});
