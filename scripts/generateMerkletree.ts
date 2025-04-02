import { MerkleTree } from "merkletreejs";
import { isAddress, keccak256 } from "ethers";
import fs from "fs";
import path from "path";
const papa = require("papaparse")

const parseAddresses = () => new Promise<string[]>((resolve, reject) => {

    console.log("Parsing addresses...")

    const addresses: string[] = [];

    const file = fs.readFileSync(path.join(__dirname, "./store/addresses.csv"), "utf8")
    papa.parse(file, {
        skipEmptyLines: true,
        step: (row: any) => {
            const data = row.data[0].replace(/'/g, "")
            if (isAddress(data)) {
                addresses.push(data)
            }
        },
        complete: () => {
            console.log("Addresses parsed successfully")
            resolve(addresses);
        },
        error: (err: any) => {
            reject(err);
        }
    })
})

parseAddresses()

const saveMerkleTreeData = (root: string, proofs: Map<string, string[]>) => {
    console.log("Saving merkletree data...")
    const merkleData = {
        root,
        proofs: Object.fromEntries(proofs)
    };

    fs.writeFileSync(
        path.join(__dirname, './store/merkletree.json'),
        JSON.stringify(merkleData, null, 2)
    );
    console.log('Merkle tree data saved to merkletree.json');
};

const generateMerkletree = async () => {
    console.log("Starting merkletree generation...")

    const addresses = await parseAddresses()

    if (!addresses) {
        console.log("Error parsing addresses")
        return
    }

    console.log("Generating merkletree...")

    const leaves = addresses.map((address) => keccak256(address))
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true })

    const root = tree.getHexRoot()

    const proofs = new Map<string, string[]>()

    for (const leaf of leaves) {
        const proof = tree.getHexProof(leaf)
        proofs.set(leaf, proof)
    }

    saveMerkleTreeData(root, proofs);

}

generateMerkletree()
