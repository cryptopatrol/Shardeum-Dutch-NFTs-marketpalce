pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DutchAuctionNFT is ERC721 {
    using SafeMath for uint256;

    uint256 public startingPrice;
    uint256 public auctionDuration;
    uint256 public minPrice;
    uint256 public auctionEndTime;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public pendingReturns;

    event AuctionEnded(address winner, uint256 highestBid);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startingPrice,
        uint256 _auctionDuration,
        uint256 _minPrice
    ) ERC721(_name, _symbol) {
        startingPrice = _startingPrice;
        auctionDuration = _auctionDuration;
        minPrice = _minPrice;
    }

    function startAuction(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can start the auction");
        require(auctionEndTime == 0, "Auction is already running");

        auctionEndTime = block.timestamp + auctionDuration;
        _safeTransfer(msg.sender, address(this), tokenId);
    }

    function placeBid() external payable {
        require(auctionEndTime > 0, "Auction has not started yet");
        require(block.timestamp <= auctionEndTime, "Auction has ended");
        require(msg.value > highestBid, "Bid must be higher than the current highest bid");

        if (highestBid != 0) {
            pendingReturns[highestBidder] = pendingReturns[highestBidder].add(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction(uint256 tokenId) external {
        require(block.timestamp > auctionEndTime, "Auction has not ended yet");
        require(ownerOf(tokenId) == address(this), "Auction contract does not own the token");

        if (highestBid > 0) {
            _transfer(address(this), highestBidder, tokenId);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            _transfer(address(this), ownerOf(tokenId), tokenId);
        }

        auctionEndTime = 0;
        highestBidder = address(0);
        highestBid = 0;
    }
}
