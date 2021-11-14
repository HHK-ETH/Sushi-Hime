import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";

let owner: SignerWithAddress;
let user: SignerWithAddress;
let linkToken: Contract;
let sushiHime: Contract;

describe("SushiHime", function () {
  before("Deploy and setup contracts", async function () {
    [owner, user] = await ethers.getSigners();
    const LinkToken = await ethers.getContractFactory("ERC20Mock");
    linkToken = await LinkToken.connect(owner).deploy(
      "LINK",
      "LINK",
      BigNumber.from(1000).mul(BigNumber.from(10).pow(18))
    );
    await linkToken.deployed();

    const SushiHime = await ethers.getContractFactory("SushiHime");
    sushiHime = await SushiHime.deploy(
      linkToken.address,
      owner.address,
      "https://tokenuri.com/",
      [0, 10000]
    );
    await sushiHime.deployed();
    linkToken.transfer(sushiHime.address, await linkToken.totalSupply());
  });

  it("Should not mint if not owner", async function () {
    await expect(
      sushiHime.connect(user).mint(user.address)
    ).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(
      sushiHime.connect(user).mintMultiple([user.address])
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not mint if no random", async function () {});
  it("Should not mint if max supply reached", async function () {});
  it("Should mint one nft", async function () {});
  it("Should mint multiple nft", async function () {});
  it("Should update token uri", async function () {});
  it("Should not updated token uri if not owner", async function () {});
});
