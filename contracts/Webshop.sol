// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vibra.sol";
import "./Escrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WebShop is Ownable {
    Vibra internal vibra;
    ShopStatus public status;
    uint256 private itemCounter;
    uint256 private availableItemsCounter;

    struct Item {
        uint256 id;
        string name;
        uint256 price;
        string url;
        address owner;
        string trackingNumber;
        address escrow;
        ItemType itemType;
        ItemStatus itemStatus;
    }
    enum ShopStatus {
        OPEN,
        RESTOCKING,
        CLOSED
    }
    enum ItemType {
        DIGITAL,
        PHYSICAL
    }
    enum ItemStatus {
        AVAILABLE,
        SOLD,
        REMOVED
    }

    mapping(uint256 => Item) private items;
    uint256[] itemList;

    event Sale(address indexed owner, address indexed buyer, uint256 price);
    event AddItem(address indexed owner, uint256 itemId);
    event CreateEscrow(
        address indexed buyer,
        address indexed owner,
        uint256 value
    );

    constructor(address _vibra) {
        vibra = Vibra(_vibra);
        itemCounter = 0;
        availableItemsCounter = 0;
    }

    function getItemCount() external view returns (uint256) {
        return itemCounter;
    }

    function getAvailableItemsCount() external view returns (uint256) {
        return availableItemsCounter;
    }

    function getItemById(uint256 _itemId) external view returns (Item memory) {
        return items[_itemId];
    }

    function buyItem(uint256 _id) public {
        Item storage item = items[_id];

        require(
            vibra.balanceOf(msg.sender) > item.price,
            "Insufficient balance"
        );
        require(
            vibra.allowance(msg.sender, address(this)) > item.price,
            "Insufficient allowance"
        );
        require(item.itemStatus == ItemStatus.AVAILABLE, "Item is unavailable");

        if (item.itemType == ItemType.PHYSICAL) {
            _buyPhysicalItem(item, msg.sender);
        } else {
            vibra.transferFrom(msg.sender, owner(), item.price);
        }

        item.owner = msg.sender;
        item.itemStatus = ItemStatus.SOLD;

        availableItemsCounter--;

        emit Sale(owner(), msg.sender, item.price);
    }

    function addItem(
        string memory _name,
        uint256 _price,
        string memory _url,
        ItemType _type
    ) public returns (bool) {
        require(status != ShopStatus.CLOSED, "Shop is closed");

        Item storage item = items[itemCounter];
        item.id = itemCounter;
        item.name = _name;
        item.price = _price;
        item.url = _url;
        item.owner = owner();
        item.itemType = _type;
        item.itemStatus = ItemStatus.AVAILABLE;

        itemList.push(itemCounter);

        emit AddItem(owner(), itemCounter);

        itemCounter++;
        availableItemsCounter++;

        return true;
    }

    function _buyPhysicalItem(Item storage _item, address _buyer)
        internal
        returns (bool)
    {
        require(
            _item.itemType == ItemType.PHYSICAL,
            "Item type must be physical"
        );

        Escrow escrow = new Escrow(
            address(vibra),
            _item.price,
            _buyer,
            owner()
        );

        escrow.deposit(_item.price);

        _item.escrow = address(escrow);

        emit CreateEscrow(msg.sender, owner(), _item.price);
        return true;
    }

    function addTrackingNumber(uint256 _id, string memory _trackingNbr) public {
        Item storage item = items[_id];
        item.trackingNumber = _trackingNbr;
    }
}
