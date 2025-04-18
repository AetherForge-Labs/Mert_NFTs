// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LetterFromOlympus is ERC721, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 3_000;
    bytes32 public merkleRoot;
    string public baseURI;
    uint256 private _totalSupply;
    mapping(address => bool) public hasMinted;
    mapping(uint256 => address) private _owners;

    constructor(
        string memory _baseURI,
        bytes32 _merkleRoot
    ) ERC721("Letter From Olympus", "LFO") Ownable(msg.sender) {
        baseURI = _baseURI;
        merkleRoot = _merkleRoot;
    }

    function mint(bytes32[] calldata _merkleProof) external {
        require(!hasMinted[msg.sender], "Already minted");
        require(_totalSupply < maxSupply, "Max supply reached");

        // Verify Merkle Proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );

        hasMinted[msg.sender] = true;
        _totalSupply++;
        uint256 tokenId = _totalSupply;
        _safeMint(msg.sender, tokenId);
        _owners[tokenId] = msg.sender;
    }

    function adminMint(uint256 _amount) external onlyOwner {
        require(_totalSupply + _amount <= maxSupply, "Max supply reached");
        for (uint256 i = 0; i < _amount; i++) {
            _totalSupply++;
            _safeMint(msg.sender, _totalSupply);
            _owners[_totalSupply] = msg.sender;
        }
        }
    }

    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    function updateBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return string(abi.encodePacked(baseURI, "/letterFromOlympus.png"));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}
