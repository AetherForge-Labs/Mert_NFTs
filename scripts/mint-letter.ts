import { JsonRpcProvider, Contract, Wallet, keccak256 } from "ethers";
const MertSpecialNFT = require("../artifacts/contracts/LetterFromOlympus.sol/LetterFromOlympus.json");
const merkleData = require("./store/merkletree.json");

import { config } from "dotenv";
config();

import { LetterFromOlympus_CA } from "../constants";

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

const adminMint = async () => {
	try {
		console.log("checking contract owner...");
		const owner = await contract.owner();
		const name = await contract.name();
		console.log("contract name", name);
		console.log("contract owner", owner);
		console.log("wallet address", wallet.address);

		// console.log("minting admin Mert Fren NFT... ");
		// const tx = await contract.AdminMint(100);
		// await tx.wait();
		// console.log("minted successfull...", tx.hash);
	} catch (error) {
		console.log("error", error);
	}
};

adminMint();
