// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vibra.sol";
import "./Escrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WebShop is Ownable {
    Vibra internal immutable vibra;
    ShopStatus public status;
    string public name;
    uint256 private itemCounter;
    uint256 private availableItemsCounter;

    struct Item {
        uint256 id;
        string name;
        uint256 price;
        string url;
        address creator;
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
        IN_TRANSIT,
        REMOVED
    }

    address[] private escrows;
    Item[] private items;

    event Sale(address indexed owner, address indexed buyer, uint256 price);
    event AddItem(address indexed owner, uint256 itemId);
    event ItemStep(
        address indexed owner,
        ItemStatus indexed itemStatus,
        uint256 itemId
    );
    event CreateEscrow(
        address indexed buyer,
        address indexed owner,
        uint256 value
    );

    constructor(address _vibra, string memory _name) {
        vibra = Vibra(_vibra);
        _name = _name;
    }

    function getItemCount() external view returns (uint256) {
        return items.length;
    }

    function getItemById(uint256 _id) external view returns (Item memory) {
        return items[_id];
    }

    function getAllItems() external view returns (Item[] memory) {
        return items;
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
            item.itemStatus = ItemStatus.IN_TRANSIT;
        } else {
            vibra.transferFrom(msg.sender, owner(), item.price);
            item.trackingNumber = "N/A";
            item.itemStatus = ItemStatus.SOLD;
        }

        item.owner = msg.sender;

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

        items.push(
            Item({
                id: items.length + 1,
                name: _name,
                price: _price,
                url: _url,
                owner: owner(),
                creator: owner(),
                trackingNumber: "",
                escrow: address(0),
                itemType: _type,
                itemStatus: ItemStatus.AVAILABLE
            })
        );

        emit AddItem(owner(), itemCounter);
        availableItemsCounter++;

        return true;
    }

    function addItems(Item[] memory _items) external onlyOwner {
        require(_items.length > 0, "Items cannot be empty");

        for (uint256 i = 0; i < _items.length; i++) {
            Item memory item = _items[i];
            items.push(item);
            availableItemsCounter++;
        }
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
        
        escrows.push(address(escrow));

        emit CreateEscrow(msg.sender, owner(), _item.price);
        return true;
    }

    function addTrackingNumber(uint256 _id, string memory _trackingNbr)
        public
        onlyOwner
    {
        Item storage item = items[_id];

        require(
            item.itemStatus == ItemStatus.IN_TRANSIT,
            "Item must be in transit"
        );

        item.trackingNumber = _trackingNbr;
        item.itemStatus = ItemStatus.IN_TRANSIT;

        emit ItemStep(item.owner, item.itemStatus, item.id);
    }

    function confirmDeliveryOfItem(uint256 _id, address _escrow) public {
        require(items[_id].escrow == _escrow, "Invalid escrow address");
        
        Escrow escrow = Escrow(_escrow);

        require(escrow.state() == Escrow.State.COMPLETE);

        Item storage item = items[_id];
        item.owner = msg.sender;
        item.itemStatus = ItemStatus.SOLD;
        
    }
}
