import { ContractFactory } from "ethers";
const bytes = require("../artifacts/contracts/MegaContract.sol/MegaProtocol.json");

async function main() {
    const factory = new ContractFactory(bytes.abi, bytes.bytecode);
    const contractSize = (factory.bytecode.length - 1) / (2 * 1024);
    console.log("Contract size:", contractSize);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
