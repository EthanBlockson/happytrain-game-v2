# HappyTrain Game (v2)

You can mint ERC721 wagons, which have unique resource type and repairable conditions. And send them to gather ERC1155 resources of 5 types. Wagons amount is limited, and repair is possible only with metal!

## Deployment details

1. Deploy **wagons.sol**

- `_baseTokenURI` — exact like `ipfs://hash/` (use [nft.storage](https://nft.storage/))

- `burner` — address, where ETH gains from wagon purchases are going to buyback clan tokens then

2. Deploy **resources.sol**

- `_baseTokenURI` — exact like `ipfs://hash/` (use [nft.storage](https://nft.storage/))

3.  `setRecourcesContract()` in **wagons.sol**

4.  `msg.sender` have to `setApprovalForAll(true)` to **wagons.sol** contract address in **resources.sol** contract to play

5.  Do not renounce owner so you can edit metadata later

## Economy

https://docs.google.com/spreadsheets/d/17yFH1PTIFT3COcvgITsKL2SY3KTySHgm6S-wz3B5eqg/edit#gid=0

## UI hints

1. Add +13 sec on UI for every timestamp because of block refreshing
2. Parse all tokenId owners and index it in the database, holding mappings address => tokenIds
