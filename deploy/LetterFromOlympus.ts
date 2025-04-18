import { ContractFactory, Wallet, JsonRpcProvider, Contract } from "ethers";
const LetterFromOlympus = require("../artifacts/contracts/LetterFromOlympus.sol/LetterFromOlympus.json")
import { config } from "dotenv";
config();

import { root, baseURI, LetterFromOlympus_CA } from "../constants";

const deploy = async () => {
    const provider = new JsonRpcProvider(process.env.RPC_URL as string);
    const wallet = new Wallet(process.env.PRIVATE_KEY as string, provider);

    // const factory = new ContractFactory(LetterFromOlympus.abi, LetterFromOlympus.bytecode, wallet);
    // const contract = await factory.deploy(baseURI, root);
    // console.log("Contract deployed to:", await contract.getAddress());

    const contract = new Contract(LetterFromOlympus_CA, LetterFromOlympus.abi, wallet);

    const tx = await contract.updateMerkleRoot(root);
    await tx.wait();

    console.log("Merkle Root set to:", root);



}

deploy()
