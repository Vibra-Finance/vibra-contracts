// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vibra.sol";

contract Escrow {
    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE
    }

    event Deposit(address indexed _from, uint256 _value);
    event Payment(address indexed _to, uint256 _value);

    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    Vibra private vibra;
    uint256 public value;
    State public state;
    address public buyer;
    address payable seller;
    address admin;

    constructor(
        address _vibra,
        uint256 _value,
        address _buyer,
        address payable _seller
    ) {
        vibra = Vibra(_vibra);
        value = _value;
        buyer = _buyer;
        seller = _seller;
        admin = msg.sender;
    }

    function deposit(uint256 amount) public onlyBuyer {
        require(
            state == State.AWAITING_PAYMENT,
            "A deposit was already completed"
        );
        require(amount == value, "Incorrect deposit amount");

        vibra.transferFrom(msg.sender, address(this), amount);

        state = State.AWAITING_DELIVERY;

        emit Deposit(msg.sender, amount);
    }

    function confirmDelivery() public onlyBuyer {
        require(
            state == State.AWAITING_DELIVERY,
            "Must be in awaiting delivery state"
        );

        vibra.transfer(seller, value);

        state = State.COMPLETE;

        emit Payment(seller, value);
    }
}
