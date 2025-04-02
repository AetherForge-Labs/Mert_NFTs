// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IMonadOneMillion {
    function balanceOf(address) external view returns (uint256);
}

contract MertFren is ERC721, Ownable {
    using Strings for uint256;
    address public MonadOneMillion;
    string public baseURI;
    uint256 public _totalSupply;
    mapping(address => bool) public hasMinted;
    mapping(uint256 => address) public _owners;

    constructor(
        string memory _baseURI,
        address _MonadOneMillion
    ) ERC721("MertNFT", "MERT") Ownable(msg.sender) {
        baseURI = _baseURI;
        MonadOneMillion = _MonadOneMillion;
    }

    function mint() external {
        require(!hasMinted[msg.sender], "Already minted");

        require(
            IMonadOneMillion(MonadOneMillion).balanceOf(msg.sender) >= 1,
            "You must hold 1 MONAD SBT"
        );

        hasMinted[msg.sender] = true;
        _totalSupply++;
        uint256 tokenId = _totalSupply;
        _safeMint(msg.sender, tokenId);
        _owners[tokenId] = msg.sender;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return string(abi.encodePacked(baseURI, "/mertnft.jpg"));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}
