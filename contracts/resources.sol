// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Resources is ERC1155, Ownable {
    using Strings for uint256;

    address internal wagons;
    uint256 public constant wood = 0;
    uint256 public constant bricks = 1;
    uint256 public constant metal = 2;
    uint256 public constant gold = 3;
    uint256 public constant ruby = 4;
    string public name;
    string public symbol;

    constructor(string memory _baseTokenURI, address wagonsAddress, string memory _name, string memory _symbol) ERC1155(_baseTokenURI) Ownable(msg.sender) {
        wagons = wagonsAddress;
        name = _name;
        symbol = _symbol;
    }

    function mintResource(address player, uint8 resource, uint256 amount) external {
        require(msg.sender == wagons, "Only wagons can mint resources");
        _mint(player, resource, amount, "");
    }

    // Override uri function to return uri based on tokenId
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId <= 4, "Unexisted tokenId");
        string memory baseURI = super.uri(tokenId); // get baseURI
        string memory tokenURI = Strings.toString(tokenId); // stringify tokenURI
        string memory fullURI = string(abi.encodePacked(baseURI, tokenURI)); // merge baseURI and tokenURI
        return fullURI;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
}
