import { keccak256 } from "ethers";
import { MerkleTree } from "merkletreejs";

const proofs = require("./store/merkletree.json");

const check = (address: string) => {
  const leaf = keccak256(address);
  const proof = proofs.proofs[leaf];

  if (!proof) {
    console.log("Address is not whitelisted");
    return;
  }

  console.log("isWhitelisted verifying this proof", proof);

  const verified = MerkleTree.verify(proof, leaf, proofs.root, keccak256, {
    sortPairs: true,
  });
  console.log("verified", verified);
};

check("0x5Ff25Ad012E218ba392F713395549A3eE12827fa");
