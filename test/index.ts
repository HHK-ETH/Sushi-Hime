import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";

let owner: SignerWithAddress;
let user: SignerWithAddress;
let linkToken: Contract;
let sushiHime: Contract;
let vrfCoordinator: Contract;

describe("SushiHime", function () {
  before("Deploy and setup contracts", async function () {
    [owner, user] = await ethers.getSigners();

    const LinkToken = await ethers.getContractFactory("LinkToken");
    linkToken = await LinkToken.deploy();
    await linkToken.deployed();

    const VRFCoordinator = await ethers.getContractFactory(
      "VRFCoordinatorMock"
    );
    vrfCoordinator = await VRFCoordinator.deploy(linkToken.address);
    await vrfCoordinator.deployed();

    const SushiHime = await ethers.getContractFactory("SushiHime");
    sushiHime = await SushiHime.deploy(
      vrfCoordinator.address,
      linkToken.address,
      "0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da",
      "https://tokenuri.com/",
      BigNumber.from(2_000),
      parseUnits("3", "ether")
    );
    await sushiHime.deployed();
    linkToken.transfer(sushiHime.address, await linkToken.totalSupply());
  });

  it("Should not mint if not unfrozen", async function () {
    await expect(sushiHime.connect(user).mint()).to.be.revertedWith(
      "SushiHime: Finish preparation first"
    );
  });

  it("Should preMint everything", async function () {
    console.log("this test takes some time...");
    for (let i = 0; i < 2_000; i += 500) {
      await sushiHime.prepare(500);
    }
    expect(await sushiHime.frozen()).to.be.equal(false);
  });

  it("Should mint one nft", async function () {
    const userBalance = await sushiHime.balanceOf(user.address);
    // fake request for randomness
    await sushiHime.connect(user).mint({ value: parseUnits("3", "ether") });
    await vrfCoordinator.callBackWithRandomness(
      await sushiHime.lastRequestId(),
      BigNumber.from(686856586),
      sushiHime.address
    );
    expect(await sushiHime.balanceOf(user.address)).to.be.equal(
      userBalance.add(1)
    );
  });

  it("Should not mint if send less than price", async function () {
    await expect(
      sushiHime.connect(user).mint({ value: parseUnits("2", "ether") })
    ).to.be.revertedWith("SushiHime: Price invalid");
  });

  it("Should not mint if max supply reached", async function () {
    this.timeout(100_000);
    console.log("this test takes some time...");
    for (let i = 1; i < 2_000; i += 1) {
      await sushiHime.connect(owner).mint();
      await vrfCoordinator.callBackWithRandomness(
        await sushiHime.lastRequestId(),
        BigNumber.from(686856586),
        sushiHime.address
      );
    }

    await expect(sushiHime.connect(owner).mint()).to.be.revertedWith(
      "SushiHime: Nothing left to mint"
    );
  });

  it("Should update token uri", async function () {
    await sushiHime.setPrefixURI("https://thisistest.com/");
    expect(await sushiHime.prefixURI()).to.be.equal("https://thisistest.com/");
  });

  it("Should not update token uri if not owner", async function () {
    await expect(
      sushiHime.connect(user).setPrefixURI("https://thisistest.com/")
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not withdraw matic if not owner", async function () {
    await expect(
      sushiHime.connect(user).withdrawMaticTokens()
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should withdraw matic", async function () {
    await sushiHime.connect(owner).withdrawMaticTokens();
    expect(await ethers.provider.getBalance(sushiHime.address)).to.be.equal(
      BigNumber.from(0)
    );
  });
});
