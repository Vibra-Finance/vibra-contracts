// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vibra.sol";

contract Trust {
    Vibra private vibra;
    address public admin;
    address public beneficiary;
    address public organization;
    uint256 public balance;
    uint256 public minBalance;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only the admin can call this function"
        );
        _;
    }

    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "Only the beneficiary can call this function"
        );
        _;
    }

    modifier onlyOrganization() {
        require(
            msg.sender == organization,
            "Only the organization can call this function"
        );
        _;
    }

    event Payment(address indexed _from, address indexed _to, uint256 _amount);
    event Deposit(address indexed _from, uint256 _amount);
    event Withdrawal(address indexed _to, uint256 _amount);
    event LowBalance(address indexed _holder, uint256 _balance);

    constructor(
        address _vibra,
        address _beneficiary,
        address _organization,
        uint256 _minBalance
    ) {
        admin = msg.sender;
        vibra = Vibra(_vibra);
        beneficiary = _beneficiary;
        organization = _organization;
        minBalance = _minBalance;
    }

    function deposit(uint256 amount) public onlyAdmin returns (bool) {
        require(
            amount > minBalance,
            "Deposit must be greater than the min balance"
        );
        require(
            vibra.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );
        require(vibra.balanceOf(msg.sender) >= amount, "Insufficient balance");

        vibra.transferFrom(msg.sender, address(this), amount);

        balance += amount;
        emit Deposit(msg.sender, amount);
        return true;
    }

    function chargeFees(uint256 amount) public onlyOrganization returns (bool) {
        require(balance > amount, "Insufficient balance");
        require(
            vibra.transfer(msg.sender, amount),
            "Unable to complete payment"
        );

        balance -= amount;
        emit Payment(address(this), organization, amount);

        if (balance <= minBalance) {
            emit LowBalance(admin, address(this).balance);
        }
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
        require(
            vibra.transferFrom(
                address(this),
                msg.sender,
                address(this).balance
            ),
            "Insufficient balance"
        );

        balance = 0;
        emit Withdrawal(msg.sender, address(this).balance);
        return true;
    }
}
