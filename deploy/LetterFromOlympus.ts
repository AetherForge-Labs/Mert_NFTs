import { ContractFactory, Wallet, JsonRpcProvider } from "ethers";
const LetterFromOlympus = require("../artifacts/contracts/LetterFromOlympus.sol/LetterFromOlympus.json")
import { config } from "dotenv";
config();

import { root, baseURI } from "../constants";

const deploy = async () => {
    const provider = new JsonRpcProvider(process.env.RPC_URL as string);
    const wallet = new Wallet(process.env.PRIVATE_KEY as string, provider);

    const factory = new ContractFactory(LetterFromOlympus.abi, LetterFromOlympus.bytecode, wallet);
    const contract = await factory.deploy(baseURI, root);
    console.log("Contract deployed to:", await contract.getAddress());
}

deploy()
