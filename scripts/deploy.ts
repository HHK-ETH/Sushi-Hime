// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { BigNumber } from "ethers";
import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const SushiHime = await ethers.getContractFactory("SushiHime");
  const sushiHime = await SushiHime.deploy(
    "0x3d2341ADb2D31f1c5530cDC622016af293177AE0",
    "0xb0897686c545045aFc77CF20eC7A532E3120E0F1",
    "0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da",
    "ipfs://QmT8iYp88GsVrDNRffeiwozBxPtCgMoK6DAdW6yjaN8XVA/",
    BigNumber.from(10_000),
    parseUnits("3", "ether")
  );

  await sushiHime.deployed();

  console.log("SushiHime deployed to:", sushiHime.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
