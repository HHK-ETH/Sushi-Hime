import * as dotenv from "dotenv";
import { Wallet } from "ethers";
import { ethers } from "hardhat";

dotenv.config();

async function main() {
  if (
    process.env.PRIVATE_KEY === undefined ||
    process.env.MUMBAI_RPC === undefined
  )
    return;
  console.log("Starting airdrop...");
  const wallet = new Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(process.env.MUMBAI_RPC)
  );
  const SushiHime = await ethers.getContractFactory("SushiHime");

  const addresses = Array(300).fill(wallet.address);

  addresses.map(async (address, index) => {
    console.log(index);
    const tx = {
      to: "0x4335359002a64fEaD7A033da7A5164cE466BdFd0",
      type: 0,
      gasPrice: 5000000000,
      gasLimit: 300_000,
      data: SushiHime.interface.encodeFunctionData("mint", [address]),
      value: "0x0",
      chainId: 80001,
      nonce: 256 + index,
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
