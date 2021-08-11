// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vibra.sol";

contract Trust {
    Vibra private vibra;
    address public admin;
    address public beneficiary;
    address public organization;
    uint256 public balance;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary);
        _;
    }

    modifier onlyOrganization() {
        require(msg.sender == organization);
        _;
    }

    event Payment(address indexed _from, address indexed _to, uint256 _amount);
    event Deposit(address indexed _from, uint256 _amount);
    event Withdrawal(address indexed _to, uint256 _amount);

    constructor(address _vibra, address _beneficiary, address _organization, uint256 _deposit) {
        admin = msg.sender;
        vibra = Vibra(_vibra);
        beneficiary = _beneficiary;
        organization = _organization;
        balance = _deposit;
    } 

    function deposit(uint256 amount) public onlyAdmin returns (bool) {
        require(vibra.allowance(msg.sender, address(this)) > amount, "Insufficient allowance");
        require(vibra.balanceOf(msg.sender) > amount, "Insufficient balance");

        vibra.transferFrom(msg.sender, address(this), amount);

        balance += amount;
        emit Deposit(msg.sender, amount);
        return true;
    }

    function payFees(uint256 amount) public onlyAdmin returns (bool) {
        require(balance > amount, "Insufficient balance");
        require(vibra.transferFrom(address(this), organization, amount), "Unable to complete payment");

        balance -= amount;
        emit Payment(msg.sender, organization, amount);
        return true;
    }

    function withdraw(uint256 amount) public onlyAdmin returns (bool) {
        require(balance > amount, "Insufficient balance");
        require(vibra.transferFrom(address(this), msg.sender, amount));

        balance -= amount;
        emit Withdrawal(msg.sender, amount);
        return true;
    }

    function withdrawAll() public onlyAdmin returns (bool) {
        require(balance > 0, "There is no balance");
        require(vibra.transferFrom(address(this), msg.sender, address(this).balance), "Insufficient balance");

        balance = 0;
        emit Withdrawal(msg.sender, address(this).balance);
        return true;
    }

}