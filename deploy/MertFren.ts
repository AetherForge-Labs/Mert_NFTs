import { ContractFactory, Wallet, JsonRpcProvider } from "ethers";
const MertFren = require("../artifacts/contracts/MertFren.sol/MertFren.json")
import { config } from "dotenv";
config();

import { baseURI, MonadOneMillion_CA } from "../constants";

const deploy = async () => {
    const provider = new JsonRpcProvider(process.env.RPC_URL as string);
    const wallet = new Wallet(process.env.PRIVATE_KEY as string, provider);

    const factory = new ContractFactory(MertFren.abi, MertFren.bytecode, wallet);
    const contract = await factory.deploy(baseURI, MonadOneMillion_CA);
    console.log("Contract deployed to:", await contract.getAddress());
}

deploy()
