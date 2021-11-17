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
    bytes32 public lastRequestId;
    address[] public addressesToMint;
    uint256[] internal availableIds;
    uint256 internal random;
    uint256 public constant MAX_SUPPLY = 10000;

    constructor(
        address _vrf,
        address _linkToken,
        string memory _prefixURI
    )
        ERC721("Sushi-Hime", "SHIME")
        VRFConsumerBase(
            _vrf, //0x3d2341ADb2D31f1c5530cDC622016af293177AE0 VRF Coordinator for polygon
            _linkToken //0xb0897686c545045aFc77CF20eC7A532E3120E0F1 LINK Token for polygon
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da; //key hash for polygon
        fee = 0.1 * 10**15; // 0.0001 LINK (on polygon)
        setPrefixURI(_prefixURI);
    }

    function addAvailableIds(uint256 _amount) public onlyOwner {
        for (uint256 i = 0; i < _amount; i+=1) {
            availableIds.push(availableIds.length);
        }
    }

    /**
     * Withdraw all Link token to owner
     */
    function withdrawLinkTokens() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    /**
     * Ask for a random number to chainlink vrf and lock the addresses to mint
     */
    function preMint(address[] calldata _to) public onlyOwner {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "SushiHime: Not enough LINK"
        );
        require(
            random == 0,
            "SushiHime: random already set"
        );
        addressesToMint = _to;
        lastRequestId = requestRandomness(keyHash, fee);
    }

    /**
     * Mint for one or multiple addresses in a single transaction
     */
    function mint() external onlyOwner {
        require(random != 0, "SushiHime: Random not set");
        require(totalSupply() + addressesToMint.length <= MAX_SUPPLY, "SushiHime: MAX_SUPPLY");
        for (uint256 i; i < addressesToMint.length; i += 1) {
            uint256 id = uint256(keccak256(abi.encodePacked(random, i))) % availableIds.length;
            _safeMint(addressesToMint[i], availableIds[id]);
            //remove the minted id from available ids.
            availableIds[id] = availableIds[availableIds.length - 1];
            availableIds.pop();
        }
        random = 0;
        delete addressesToMint; //save gas
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
            "ERC721Metadata: nonexistent token"
        );
        return
            string(abi.encodePacked(prefixURI, _tokenId.toString(), ".json"));
    }

    /**
     * Set prefixURI
     */
    function setPrefixURI(string memory _prefixURI) public onlyOwner {
        prefixURI = _prefixURI;
    }
}
