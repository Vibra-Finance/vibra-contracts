// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Item.sol";

contract ItemManager is Ownable {
    enum SupplyChainSteps {
        Created,
        Paid,
        Delivered
    }

    struct S_Item {
        ItemManager.SupplyChainSteps _step;
        string _identifier;
        uint256 _priceInWei;
    }
    mapping(uint256 => S_Item) public items;
    uint256 index;

    event SupplyChainStep(uint256 _itemIndex, uint256 _step);

    function createItem(string memory _identifier, uint256 _priceInWei)
        public
        onlyOwner
    {
        items[index]._priceInWei = _priceInWei;
        items[index]._step = SupplyChainSteps.Created;
        items[index]._identifier = _identifier;
        emit SupplyChainStep(index, uint256(items[index]._step));
        index++;
    }

    function triggerPayment(uint256 _index) public payable {
        require(items[_index]._priceInWei <= msg.value, "Not fully paid");
        require(
            items[_index]._step == SupplyChainSteps.Created,
            "Item is further in the supply chain"
        );
        items[_index]._step = SupplyChainSteps.Paid;
        emit SupplyChainStep(_index, uint256(items[_index]._step));
    }

    function triggerDelivery(uint256 _index) public onlyOwner {
        require(
            items[_index]._step == SupplyChainSteps.Paid,
            "Item is further in the supply chain"
        );
        items[_index]._step = SupplyChainSteps.Delivered;
        emit SupplyChainStep(_index, uint256(items[_index]._step));
    }
}
