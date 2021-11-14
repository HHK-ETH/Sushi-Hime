//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract SushiHime is Ownable, VRFConsumerBase, ERC721Enumerable {
    using Strings for uint256;

    bytes32 internal keyHash;
    uint256 internal fee;

    string public prefixURI;
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public random;
    uint256[] public availableIds;

    constructor(
        string memory _prefixURI,
        uint256[] memory _availableIds //must have equal length than MAX_SUPPLY and go from 0 to MAX_SUPPLY - 1
    )
        ERC721("Sushi-Hime", "SHIME")
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, //VRF Coordinator for polygon
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1 //LINK Token for polygon
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da; //key hash for polygon
        fee = 0.1 * 10**15; // 0.0001 LINK (on polygon)
        setPrefixURI(_prefixURI);
        availableIds = _availableIds;
    }

    /**
     * Withdraw all Link token to owner
     */
    function withdrawLinkTokens() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    /**
     * Ask for a random number to chainlink vrf
     */
    function requestRandomness() public onlyOwner {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        requestRandomness(keyHash, fee);
    }

    /**
     * Mint for multiple addresses in a single transaction
     */
    function mintMultiple(address[] memory _to) external onlyOwner {
        require(random != 0, "Can not mint if random not set");
        for (uint256 i; i < _to.length; i += 1) {
            require(totalSupply() <= MAX_SUPPLY, "All nft already minted");
            uint256 id = random % availableIds.length;
            _safeMint(_to[i], availableIds[id]);
            //update random and remove the minted id from available ids.
            availableIds[id] = availableIds[availableIds.length - 1];
            availableIds.pop();
            random = uint256(keccak256(abi.encodePacked(random, i)));
        }
        random = 0;
    }

    /**
     * Mint for 1 address
     */
    function mint(address _to) external onlyOwner {
        require(random != 0, "Can not mint if random not set");
        require(totalSupply() <= MAX_SUPPLY, "All nft already minted");
        uint256 id = random % availableIds.length;
        _safeMint(_to, availableIds[id]);
        //remove random and the minted id from available ids.
        availableIds[id] = availableIds[availableIds.length - 1];
        availableIds.pop();
        random = 0;
    }

    /**
     * Callback function used by VRF Coordinator to mint the NFT
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        random = randomness;
    }

    /**
     * Return tokenURI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(prefixURI, _tokenId.toString(), ".json"));
    }

    /**
     * Set prefixURI
     */
    function setPrefixURI(string memory _prefixURI) public onlyOwner {
        prefixURI = _prefixURI;
    }

}
