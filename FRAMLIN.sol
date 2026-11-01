// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Agent Framlin
/// @notice Pixel agents on BNB Chain. Supply 4,567 in one pool.
/// Phase 1A: tokens minted while totalMinted < 300, free (0 BNB), max 3 per tx.
/// Phase 1B: tokens minted while 300 <= totalMinted < 1000, free NFT + 0.00015 BNB fee per NFT, max 3 per tx.
/// Phase 2: tokens minted while totalMinted >= 1000, 0.003 BNB per NFT, max 5 per tx.
/// Minting is sequential by token id, so phase ranges match token ids #1-#300, #301-#1000, #1001-#4567.
/// Mint is CLOSED at deploy (mintEnabled = false). It can only be opened later
/// when the owner wallet itself signs setMintEnabled(true). Deploying does NOT open mint.
/// All mint payments are sent to this contract and stay here until the owner
/// withdraws them. There is no treasury address.
contract FRAMLIN is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 4567;
    uint256 public constant FREE_LIMIT = 300;
    uint256 public constant FREE_FEE_LIMIT = 1000;
    uint256 public constant FEE_FEE = 0.00015 ether;
    uint256 public constant PAID_PRICE = 0.003 ether;
    uint256 public constant MAX_PER_TX_FREE = 3;
    uint256 public constant MAX_PER_TX_PAID = 5;

    uint256 public totalMinted;
    bool public mintEnabled;
    string private _baseTokenURI;

    event MintEnabledChanged(bool enabled);
    event BaseURIChanged(string baseURI);

    constructor() ERC721("Agent Framlin", "FRAMLIN") Ownable(msg.sender) {}

    function _mintNext(address to) internal {
        totalMinted += 1;
        _safeMint(to, totalMinted);
    }

    function mintFree(uint256 amount) external {
        require(mintEnabled, "Mint closed");
        require(amount > 0 && amount <= MAX_PER_TX_FREE, "Max 3 per mint");
        require(totalMinted + amount <= FREE_LIMIT, "Free phase ended");
        for (uint256 i = 0; i < amount; i++) _mintNext(msg.sender);
    }

    function mintFreeFee(uint256 amount) external payable {
        require(mintEnabled, "Mint closed");
        require(amount > 0 && amount <= MAX_PER_TX_FREE, "Max 3 per mint");
        require(totalMinted >= FREE_LIMIT, "Fee phase not started");
        require(totalMinted + amount <= FREE_FEE_LIMIT, "Fee phase ended");
        require(msg.value == FEE_FEE * amount, "Wrong fee");
        for (uint256 i = 0; i < amount; i++) _mintNext(msg.sender);
    }

    function mintPaid(uint256 amount) external payable {
        require(mintEnabled, "Mint closed");
        require(amount > 0 && amount <= MAX_PER_TX_PAID, "Max 5 per mint");
        require(totalMinted >= FREE_FEE_LIMIT, "Paid phase not started");
        require(totalMinted + amount <= MAX_SUPPLY, "Sold out");
        require(msg.value == PAID_PRICE * amount, "Wrong price");
        for (uint256 i = 0; i < amount; i++) _mintNext(msg.sender);
    }

    function setMintEnabled(bool enabled) external onlyOwner {
        mintEnabled = enabled;
        emit MintEnabledChanged(enabled);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        (bool ok, ) = owner().call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }
}
