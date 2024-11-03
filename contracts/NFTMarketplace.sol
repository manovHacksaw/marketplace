// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    address payable owner;
    uint256 private _tokenIds = 0;
    uint256 private _itemsSold = 0;
    uint256 public listPrice = 100 ether;

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    mapping(uint256 => ListedToken) idToListedToken;

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint) {
        require(msg.value == listPrice, "Send the correct price to list");
        require(price > 0, "Price must be greater than zero");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        idToListedToken[newTokenId] = ListedToken({
            tokenId: newTokenId,
            owner: payable(address(this)),
            seller: payable(msg.sender),
            price: price,
            currentlyListed: true
        });

        _transfer(msg.sender, address(this), newTokenId);

        return newTokenId;
    }

    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint256 nftCount = _tokenIds;
        ListedToken[] memory tokens = new ListedToken[](nftCount);

        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= nftCount; i++) {
            tokens[currentIndex] = idToListedToken[i];
            currentIndex++;
        }
        return tokens;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint256 totalNFTCount = _tokenIds;
        uint256 myNFTCount = 0;

        // Count the number of NFTs owned by the caller
        for (uint256 i = 1; i <= totalNFTCount; i++) {
            if (idToListedToken[i].owner == msg.sender) {
                myNFTCount++;
            }
        }

        // Create an array to hold the caller's NFTs
        ListedToken[] memory myTokens = new ListedToken[](myNFTCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalNFTCount; i++) {
            if (idToListedToken[i].owner == msg.sender) {
                myTokens[currentIndex] = idToListedToken[i];
                currentIndex++;
            }
        }

        return myTokens;
    }

    function executeSale(uint256 tokenId) public payable {
        ListedToken storage listedToken = idToListedToken[tokenId];

        // Ensure the token is currently listed for sale
        require(
            listedToken.currentlyListed,
            "This token is not currently listed for sale"
        );

        // Ensure the buyer sent the correct price
        require(
            msg.value == listedToken.price,
            "Please submit the asking price in order to complete the purchase"
        );

        // Transfer the sale price to the seller
        listedToken.seller.transfer(msg.value);

        // Transfer ownership of the token to the buyer
        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);

        // Update the token's listing status
        listedToken.currentlyListed = false;
        listedToken.owner = payable(msg.sender);
        listedToken.seller = payable(address(0)); // Clear the seller address since it's no longer listed

        // Increment the count of sold items
        _itemsSold++;
    }

    function updateListPrice(uint256 _listPrice) public {
        require(owner == msg.sender, "Only owner can update the price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken()
        public
        view
        returns (ListedToken memory)
    {
        uint256 currentTokenId = _tokenIds;
        return idToListedToken[currentTokenId];
    }

    function getListedForTokenId(
        uint256 tokenId
    ) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds;
    }
}
