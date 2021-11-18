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
    "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255",
    "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4",
    "https://uri.com/",
    BigNumber.from(2_000),
    parseUnits("3", "ether")
  );

  await sushiHime.deployed();

  console.log("Greeter deployed to:", sushiHime.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
