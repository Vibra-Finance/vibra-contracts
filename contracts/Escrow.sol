// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vibra.sol";

contract Escrow is Ownable {
    State public state;
    Vibra internal vibra;
    uint256 internal value;
    address public buyer;
    address public seller;

    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        DISPUTED,
        CANCELED,
        COMPLETE
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function");
        _;
    }

    event Deposit(address indexed _from, uint256 _value);
    event Payment(address indexed _to, uint256 _value);
    event Refund(address _to, uint256 _value);
    event Dispute(
        address indexed _buyer,
        address indexed _seller,
        uint256 _value
    );

    constructor(
        address _vibra,
        uint256 _value,
        address _buyer,
        address _seller
    ) {
        vibra = Vibra(_vibra);
        value = _value;
        buyer = _buyer;
        seller = _seller;
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

    function dispute() public onlyBuyer {
        require(
            state == State.AWAITING_DELIVERY,
            "Must be in awaiting delivery state"
        );
        state = State.DISPUTED;

        emit Dispute(buyer, seller, value);
    }

    function processRefund() public onlyOwner {
        require(state == State.DISPUTED, "Must be in disputed state");

        vibra.transfer(buyer, value);
        emit Refund(buyer, value);

        state = State.CANCELED;
        value = 0;
    }
}
