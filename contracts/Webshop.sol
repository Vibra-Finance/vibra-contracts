// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vibra.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WebShop is Ownable {
    Vibra internal vibra;
    ShopStatus public status;

    struct Item {
        uint256 id;
        string name;
        uint256 price;
        string url;
        address owner;
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

    mapping(uint256 => Item) items;
    uint256[] itemList;

    event Sale(address indexed buyer, uint256 itemId);
    event AddItem(address indexed owner, uint256 itemId);

    constructor(address _vibra) {
        vibra = Vibra(_vibra);
    }

    function getItemCount() external view returns (uint256) {
        return itemList.length;
    }

    function getItemById(uint256 _itemId)
        external
        view
        returns (Item memory item)
    {
        return items[_itemId];
    }
}
