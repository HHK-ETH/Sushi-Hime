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
    mapping (uint256 => uint256) public uriIds;
    mapping (bytes32 => address) public requestIds;
    uint256 public constant MAX_SUPPLY = 10000;
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
     * Mint for multiple addresses in a single transaction
     */
    function mintMultiple(address[] memory _to) external onlyOwner {
        for (uint256 i; i < _to.length; i += 1) {
            mint(_to[i]);
        }
    }

    /**
     * Mint for 1 address
     */
    function mint(address _to) public onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "All nft already minted");
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIds[requestId] = _to;
    }

    /**
     * Callback function used by VRF Coordinator to mint the NFT
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address to = requestIds[requestId];
        uint256 id = randomness % availableIds.length;
        _safeMint(to, availableIds[id]);
        //remove the minted id from available ids.
        availableIds[id] = availableIds[availableIds.length - 1];
        availableIds.pop();
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
