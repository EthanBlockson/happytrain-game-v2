// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface IResources {
    function mintResource(address player, uint8 resource, uint256 amount) external; // call resources contract to mint

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(
            address from,
            address to,
            uint256 id,
            uint256 amount,
            bytes calldata data
        ) external;
}

contract Wagons is ERC721URIStorage, Ownable {
    using Strings for uint256;

    address public resourcesContract;
    address public burnerContract;
    string private baseTokenURI;
    uint256 private _nextTokenId; // Global incrementer
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public testnetSumMinimizer = 100000; // TEMP, To use less ether while testing
    uint32 public testnetTimeMinmizer = 10000; // TEMP, To wait less time while testing

    constructor(string memory _baseTokenURI, address burner) ERC721("Unit", "UNIT") Ownable(msg.sender) {
        baseTokenURI = _baseTokenURI;
        burnerContract = burner;
    }

    struct Wagon {
        uint8 level;
        uint8 condition;
        uint32 claimAmount; 
        uint256 cooldown;
    }
    mapping(uint256 => Wagon) wagons;
    mapping(uint8 => uint16) totalWagons;

    uint256[21] public levelPrice = [
        0 ether / testnetSumMinimizer,       // Level 0, empty
        0.005 ether / testnetSumMinimizer,   // Level 1, wood
        0.007 ether / testnetSumMinimizer,   // Level 2, wood
        0.01 ether / testnetSumMinimizer,    // Level 3, wood
        0.016 ether / testnetSumMinimizer,   // Level 4, wood
        0.016 ether / testnetSumMinimizer,   // Level 5, bricks
        0.025 ether / testnetSumMinimizer,   // Level 6, bricks
        0.04 ether / testnetSumMinimizer,    // Level 7, bricks
        0.055 ether / testnetSumMinimizer,   // Level 8, bricks
        0.055 ether / testnetSumMinimizer,   // Level 9, metal
        0.08 ether / testnetSumMinimizer,    // Level 10, metal
        0.12 ether / testnetSumMinimizer,    // Level 11, metal
        0.18 ether / testnetSumMinimizer,    // Level 12, metal
        0.18 ether / testnetSumMinimizer,    // Level 13, gold
        0.27 ether / testnetSumMinimizer,    // Level 14, gold
        0.41 ether / testnetSumMinimizer,    // Level 15, gold
        0.62 ether / testnetSumMinimizer,    // Level 16, gold
        0.62 ether / testnetSumMinimizer,    // Level 17, ruby
        0.93 ether / testnetSumMinimizer,    // Level 18, ruby
        1.4 ether / testnetSumMinimizer,     // Level 19, ruby
        2.11 ether / testnetSumMinimizer     // Level 20, ruby
    ];

    uint16[21] public maxWagons = [
        0,    // Level 0, empty
        1000, // Level 1, wood
        1000, // Level 2, wood
        1000, // Level 3, wood
        1000, // Level 4, wood
        700,  // Level 5, bricks
        700,  // Level 6, bricks
        700,  // Level 7, bricks
        700,  // Level 8, bricks
        500,  // Level 9, metal
        500,  // Level 10, metal
        500,  // Level 11, metal
        500,  // Level 12, metal
        300,  // Level 13, gold
        300,  // Level 14, gold
        300,  // Level 15, gold
        300,  // Level 16, gold
        100,  // Level 17, ruby
        100,  // Level 18, ruby
        100,  // Level 19, ruby
        100   // Level 20, ruby
    ];

    uint8[21] public resourceType = [
        0, // Level 0, empty
        0, // Level 1, wood
        0, // Level 2, wood
        0, // Level 3, wood
        0, // Level 4, wood
        1, // Level 5, bricks
        1, // Level 6, bricks
        1, // Level 7, bricks
        1, // Level 8, bricks
        2, // Level 9, metal
        2, // Level 10, metal
        2, // Level 11, metal
        2, // Level 12, metal
        3, // Level 13, gold
        3, // Level 14, gold
        3, // Level 15, gold
        3, // Level 16, gold
        4, // Level 17, ruby
        4, // Level 18, ruby
        4, // Level 19, ruby
        4  // Level 20, ruby
    ];

    uint16[21] public resourceGains = [
        0,    // Level 0, empty
        1024, // Level 1, wood
        1024, // Level 2, wood
        1024, // Level 3, wood
        1024, // Level 4, wood
        512,  // Level 5, bricks
        512,  // Level 6, bricks
        512,  // Level 7, bricks
        512,  // Level 8, bricks
        256,  // Level 9, metal
        256,  // Level 10, metal
        256,  // Level 11, metal
        256,  // Level 12, metal
        128,  // Level 13, gold
        128,  // Level 14, gold
        128,  // Level 15, gold
        128,  // Level 16, gold
        64,   // Level 17, ruby
        64,   // Level 18, ruby
        64,   // Level 19, ruby
        64    // Level 20, ruby
    ];

    uint32[21] public workTime = [
        0,     // Level 0, empty
        10800 / testnetTimeMinmizer, // Level 1, wood
        9720 / testnetTimeMinmizer,  // Level 2, wood
        8640 / testnetTimeMinmizer,  // Level 3, wood
        7128 / testnetTimeMinmizer,  // Level 4, wood
        21600 / testnetTimeMinmizer, // Level 5, bricks
        19440 / testnetTimeMinmizer, // Level 6, bricks
        17280 / testnetTimeMinmizer, // Level 7, bricks
        14256 / testnetTimeMinmizer, // Level 8, bricks
        43200 / testnetTimeMinmizer, // Level 9, metal
        38880 / testnetTimeMinmizer, // Level 10, metal
        34560 / testnetTimeMinmizer, // Level 11, metal
        28512 / testnetTimeMinmizer, // Level 12, metal
        86400 / testnetTimeMinmizer, // Level 13, gold
        77760 / testnetTimeMinmizer, // Level 14, gold
        69120 / testnetTimeMinmizer, // Level 15, gold
        57024 / testnetTimeMinmizer, // Level 16, gold
        172800 / testnetTimeMinmizer,// Level 17, ruby
        155520 / testnetTimeMinmizer,// Level 18, ruby
        138240 / testnetTimeMinmizer,// Level 19, ruby
        114048 / testnetTimeMinmizer // Level 20, ruby
    ];

    uint16[21] public repairCost = [
        0,   // Level 0, empty
        32,  // Level 1, wood
        32,  // Level 2, wood
        32,  // Level 3, wood
        32,  // Level 4, wood
        64,  // Level 5, bricks
        64,  // Level 6, bricks
        64,  // Level 7, bricks
        64,  // Level 8, bricks
        128, // Level 9, metal
        128, // Level 10, metal
        128, // Level 11, metal
        128, // Level 12, metal
        256, // Level 13, gold
        256, // Level 14, gold
        256, // Level 15, gold
        256, // Level 16, gold
        512, // Level 17, ruby
        512, // Level 18, ruby
        512, // Level 19, ruby
        512  // Level 20, ruby    
    ];

    function buyWagon(uint8 level) public payable {
        require(totalWagons[level] < maxWagons[level], "Max wagons amount on this level reached");
        require(level > 0 && level < levelPrice.length, "Level doesn't exist");
        require(msg.value == levelPrice[level], "Level cost another sum");
        uint256 tokenId = _nextTokenId++; // increment tokenId
        wagons[tokenId].level = level; // set level for tokenId
        wagons[tokenId].condition = level * 10; // 10 conditions for every wagon with unique path to metadata
        string memory conditionURI = Strings.toString(wagons[tokenId].condition); // stringify tokenURI

        if (msg.value == levelPrice[level]) {
            _mint(msg.sender, tokenId); // mint wagon
            _setTokenURI(tokenId, conditionURI); // set tokenURI
        }

        payable(burnerContract).transfer(msg.value); // send eth to burner contract
        totalWagons[level]++; // increment total wagons
    }

    function goToWork(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner of wagon can send it to work");
        require(wagons[tokenId].condition != wagons[tokenId].level * 10 - 10, "Wagon is completely broken");
        require(wagons[tokenId].cooldown < block.timestamp, "Wagon hasn't back from work yet");
        require(wagons[tokenId].claimAmount == 0, "Wagon hasn't back from work yet");
        wagons[tokenId].condition -= 1; // downgrade condition
        wagons[tokenId].cooldown = block.timestamp + workTime[wagons[tokenId].level]; // add cooldown
        wagons[tokenId].claimAmount += resourceGains[wagons[tokenId].level]; // identify resource and amount to get
        string memory conditionURI = Strings.toString(wagons[tokenId].condition); // stringify tokenURI
        _setTokenURI(tokenId, conditionURI); // change tokenURI
    }

    function backFromWork(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner of wagon can get wagon back");
        require(wagons[tokenId].cooldown < block.timestamp, "Wagon is still going for resources");
        require(wagons[tokenId].claimAmount > 0, "Wagon hasn't done any work");
        IResources resources = IResources(resourcesContract); // init 1155 interface
        resources.mintResource(msg.sender, resourceType[wagons[tokenId].level], wagons[tokenId].claimAmount); // mint resource
        wagons[tokenId].claimAmount = 0; // clear claimable amount
        // clearing cooldown is gas inefficient
    }

    function repairWagon(uint256 tokenId, uint8 conditionLevelsUp) public {
        IResources resources = IResources(resourcesContract); // init 1155 interface
        uint32 metalAmount = repairCost[wagons[tokenId].level]; // identify metal amount for repair
        require(resources.isApprovedForAll(msg.sender, address(this)), "Your metal isn't approved for transfer by this contract");
        require(resources.balanceOf(msg.sender, 2) >= metalAmount * conditionLevelsUp, "Not enough metal for this repair");
        require(wagons[tokenId].condition + conditionLevelsUp <= wagons[tokenId].level * 10, "Too much levels for repair");
        require(wagons[tokenId].condition != wagons[tokenId].level * 10, "Wagon is completely repaired");
        require(wagons[tokenId].cooldown < block.timestamp, "Wagon hasn't back from work yet");
        require(wagons[tokenId].claimAmount == 0, "Wagon hasn't back from work yet");
        resources.safeTransferFrom(msg.sender, deadAddress, 2, metalAmount, ""); // burn metal
        wagons[tokenId].condition += conditionLevelsUp; // repair
        string memory conditionURI = Strings.toString(wagons[tokenId].condition); // stringify tokenURI
        _setTokenURI(tokenId, conditionURI); // change tokenURI
    }

    function getWagonData(uint256 wagonId) public view returns (
        uint8,
        uint8,
        uint32,
        uint256
    ) {
        Wagon storage wagon = wagons[wagonId];
        return (
            wagon.level,
            wagon.condition,
            wagon.claimAmount,
            wagon.cooldown
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function setResourcesContract(address _resourcesContract) public onlyOwner {
        require(resourcesContract == address(0), "Resources contract is already set");
        resourcesContract = _resourcesContract;
    }
}