import * as dotenv from "dotenv";
import { Wallet } from "ethers";
import { ethers } from "hardhat";

dotenv.config();

async function main() {
  if (
    process.env.PRIVATE_KEY === undefined ||
    process.env.POLYGON_RPC === undefined
  )
    return;
  console.log("Starting airdrop...");
  const wallet = new Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(process.env.POLYGON_RPC)
  );
  const SushiHime = await ethers.getContractFactory("SushiHime");

  const addresses = ["0xBaf381183A2ffecb3Ac7929D704277Ba45AE87Df"];

  addresses.map(async (address, index) => {
    console.log(index);
    const tx = {
      to: "0xed253733a7a4bf8bdbaa5579c8a9829862255485",
      type: 0,
      gasPrice: 40_000000000,
      gasLimit: 300_000,
      data: SushiHime.interface.encodeFunctionData("mint", [address]),
      value: "0x0",
      chainId: 137,
      nonce: 39 + index,
    };
    await wallet.sendTransaction(tx);
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
