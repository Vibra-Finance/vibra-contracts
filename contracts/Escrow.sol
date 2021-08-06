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

    Vibra public vibra;
    uint256 public value;
    State public state;
    address public buyer;
    address payable seller;
    address admin;

    constructor(
        Vibra _vibra,
        uint256 _value,
        address payable _seller,
        address _buyer
    ) public {
        vibra = _vibra;
        value = _value;
        seller = _seller;
        buyer = _buyer;
        admin = msg.sender;
    }

    function deposit(uint256 amount) public onlyBuyer {
        require(state == State.AWAITING_PAYMENT);
        require(amount == value);

        vibra.increaseAllowance(msg.sender, amount);
        vibra.transfer(msg.sender, amount);

        state = State.AWAITING_DELIVERY;
      
        emit Deposit(msg.sender, amount);
    }

    function confirmDelivery() public onlyBuyer {
        require(state == State.AWAITING_DELIVERY);

        seller.transfer(address(this).balance);

        emit Payment(seller, address(this).balance);
    }
}
