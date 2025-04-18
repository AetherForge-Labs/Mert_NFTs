import { JsonRpcProvider, Contract, Wallet, keccak256 } from "ethers";
const MertFren = require("../artifacts/contracts/MertFren.sol/MertFren.json");

import { config } from "dotenv";
config();

import { MertFren_CA, MonadOneMillion_CA } from "../constants";

const provider = new JsonRpcProvider(process.env.RPC_URL as string);
const wallet = new Wallet(process.env.PKEY_3 as string, provider);

const contract = new Contract(MertFren_CA as string, MertFren.abi, wallet);

const oneMillionNFT = new Contract(
	MonadOneMillion_CA as string,
	MertFren.abi,
	wallet
);

const mint = async () => {
	try {
		console.log("Checking wallet and balance ");
		console.log("wallet address", wallet.address);
		console.log("balance", await oneMillionNFT.balanceOf(wallet.address));

		console.log("minting Mert Fren NFT... ");
		const tx = await contract.mint();
		await tx.wait();
		console.log("minted successfull...", tx.hash);
	} catch (error) {
		console.log("error", error);
	}
};
mint();
