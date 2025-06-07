import { JsonRpcProvider, Contract, Wallet, keccak256 } from "ethers";
const MertSpecialNFT = require("../artifacts/contracts/LetterFromOlympus.sol/LetterFromOlympus.json");
const merkleData = require("./store/merkletree.json");
import {parseAddresses} from "./generateMerkletree";
import fsPromise from "fs/promises"
import {address} from "./store/newAddress"

import { config } from "dotenv";
config();

import { LetterFromOlympus_CA } from "../constants";
import path from "path";

const provider = new JsonRpcProvider(process.env.RPC_URL as string);
const wallet = new Wallet(process.env.PRIVATE_KEY as string, provider);

const contract = new Contract(
	LetterFromOlympus_CA as string,
	MertSpecialNFT.abi,
	wallet
);

const mint = async () => {
	console.log("minting Letter From Olympus... ");
	const _proofs = merkleData.proofs;
	const proof = _proofs[keccak256(wallet.address)];

	if (!proof) {
		console.log("You are not whitelisted");
		return;
	}
	console.log("proof", proof);

	const tx = await contract.mint(proof);

	await tx.wait();
	console.log("minted successfull...", tx.hash);
};
// mint();


const hasMinted = async () => {
	try {
		console.log("checking if users has minted...");

        const addreses = await parseAddresses();
		const newAddress: string[] = []

        for( const addy of addreses) {
            const hasMinted = await contract.hasMinted(addy);
			console.log(`${addy} hasMinted ? ---  ${hasMinted}`)
			if(hasMinted) {
				newAddress.push(addy)
			}
        }

		console.log("we've filtered addresses to ...", newAddress.length)
		const res = await fsPromise.appendFile(path.join(__dirname, "/store/newAddress.txt"), JSON.stringify(newAddress), {encoding: "utf8"})

		console.log("res from file...",res)
		
	} catch (error) {
		console.log("error", error);
	}
};

// hasMinted();

const updateMerkleTree = async () => {
	const newRoot = "0xfc7575432fd3461fe4d777a3ae4787cb5b770f8291bf000432c870543fcb3a6b";
	const tx = await contract.updateMerkleRoot(newRoot);
	await tx.wait();
	console.log("tx", tx);
}
updateMerkleTree();