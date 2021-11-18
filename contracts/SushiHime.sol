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

    uint256[] internal unclaimedNfts;
    mapping (bytes32 => address) internal mintRequests;
    bytes32 public lastRequestId;
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable PRICE;
    bool public frozen = true;

    constructor(
        address _vrf,
        address _linkToken,
        bytes32 _keyHash,
        string memory _prefixURI,
        uint256 _maxSupply,
        uint256 _price
    )
        ERC721("Sushi-Hime", "SHIME")
        VRFConsumerBase(
            _vrf, //0x3d2341ADb2D31f1c5530cDC622016af293177AE0 VRF Coordinator for polygon
            _linkToken //0xb0897686c545045aFc77CF20eC7A532E3120E0F1 LINK Token for polygon
        )
    {
        keyHash = _keyHash; //key hash for polygon
        fee = 0.1 * 10**15; // 0.0001 LINK (on polygon)
        setPrefixURI(_prefixURI);
        MAX_SUPPLY = _maxSupply;
        PRICE = _price;
    }

    /**
     * Withdraw all Link token to owner
     */
    function withdrawLinkTokens() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    /**
     * Create nft ids array to unfreeze the contract.
     */
    function prepare(uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i += 1) {
            uint256 id = unclaimedNfts.length;
            unclaimedNfts.push(id);
        }
        if (unclaimedNfts.length == MAX_SUPPLY) frozen = false;
    }

    /**
     * Mint for one or multiple addresses in a single transaction
     */
    function mint(address _to) external payable {
        require(frozen == false, "SushiHime: Finish preparation first");
        require(unclaimedNfts.length > 0, "SushiHime: Nothing left to mint");
        uint price = PRICE;
        if (msg.sender == owner()) price = 0 ether; //free for owner (airdrop)
        require(msg.value >= price, "SushiHime: Price invalid");
        require(LINK.balanceOf(address(this)) >= fee, "SushiHime: Not enough LINK");
        bytes32 requestId = requestRandomness(keyHash, fee);
        lastRequestId = requestId;
        mintRequests[requestId] = _to;
    }

    /**
     * Callback function used by VRF Coordinator to mint the NFT
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 id = randomness % unclaimedNfts.length;
        _mint(mintRequests[requestId], unclaimedNfts[id]);
        unclaimedNfts[id] = unclaimedNfts[unclaimedNfts.length - 1];
        unclaimedNfts.pop();
        delete mintRequests[requestId]; //save gas
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
    
    /**
     * Withdraw MATIC
     */
    function withdrawMaticTokens() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "SushiHime: transfer failed");
    }
}
