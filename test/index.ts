import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
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
    linkToken = await LinkToken.connect(owner).deploy();
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
      "https://tokenuri.com/"
    );
    await sushiHime.deployed();
    linkToken.transfer(sushiHime.address, await linkToken.totalSupply());
    for (let i = 0; i < 10; i += 1) {
      await sushiHime.addAvailableIds(1_000);
    }
  });

  it("Should not mint if not owner", async function () {
    await expect(sushiHime.connect(user).mint()).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });

  it("Should not mint if no random", async function () {
    await expect(sushiHime.connect(owner).mint()).to.be.revertedWith(
      "SushiHime: Random not set"
    );
  });

  it("Should mint one nft", async function () {
    const totalSupply = await sushiHime.totalSupply();
    // fake request for randomness
    await sushiHime.preMint([user.address]);
    await vrfCoordinator.callBackWithRandomness(
      await sushiHime.lastRequestId(),
      BigNumber.from(686856586),
      sushiHime.address
    );
    await sushiHime.mint();
    expect(await sushiHime.totalSupply()).to.be.equal(totalSupply.add(1));
  });

  it("Should mint multiple nfts", async function () {
    const totalSupply = await sushiHime.totalSupply();
    // fake request for randomness
    await sushiHime.preMint(Array(99).fill(user.address));
    await vrfCoordinator.callBackWithRandomness(
      await sushiHime.lastRequestId(),
      BigNumber.from(686856586),
      sushiHime.address
    );
    await sushiHime.mint();
    expect(await sushiHime.totalSupply()).to.be.equal(totalSupply.add(99));
  });

  it("Should not mint if max supply reached", async function () {
    this.timeout(100_000);
    console.log("this test takes some time...");
    for (let i = 100; i < 10_000; i += 100) {
      // fake request for randomness
      await sushiHime.preMint(Array(100).fill(user.address));
      await vrfCoordinator.callBackWithRandomness(
        await sushiHime.lastRequestId(),
        BigNumber.from(686856586),
        sushiHime.address
      );
      await sushiHime.mint();
    }
    await sushiHime.preMint([user.address]);
    await vrfCoordinator.callBackWithRandomness(
      await sushiHime.lastRequestId(),
      BigNumber.from(686856586),
      sushiHime.address
    );
    await expect(sushiHime.connect(owner).mint()).to.be.revertedWith(
      "SushiHime: MAX_SUPPLY"
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
});
