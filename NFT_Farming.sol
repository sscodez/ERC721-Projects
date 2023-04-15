pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NFTFarming is ERC721Holder {
    IERC721 public nftToken;
    IERC20 public rewardToken;

    mapping(address => uint256) public stakedNFTs;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewards;

    uint256 public rewardRate = 1e18;
    uint256 public minimumStakeTime = 1 days;

    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(IERC721 _nftToken, IERC20 _rewardToken) {
        nftToken = _nftToken;
        rewardToken = _rewardToken;
    }

    function stake(uint256 tokenId) external {
        require(nftToken.ownerOf(tokenId) == msg.sender, "Not the owner of the NFT");
        require(stakedNFTs[msg.sender] == 0, "Already staked an NFT");

        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);

        stakedNFTs[msg.sender] = tokenId;
        lastUpdateTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, tokenId);
    }

    function unstake() external {
        require(stakedNFTs[msg.sender] != 0, "No staked NFT found");

        uint256 tokenId = stakedNFTs[msg.sender];
        stakedNFTs[msg.sender] = 0;
        lastUpdateTime[msg.sender] = 0;

        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, tokenId);
    }

    function claimRewards() external {
        require(stakedNFTs[msg.sender] != 0, "No staked NFT found");

        uint256 reward = calculateReward(msg.sender);
        rewards[msg.sender] = 0;

        rewardToken.transfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 stakingDuration = block.timestamp - lastUpdateTime[user];

        return stakingDuration * rewardRate;
    }

    function setRewardRate(uint256 _rewardRate) external {
        rewardRate = _rewardRate;
    }

    function setMinimumStakeTime(uint256 _minimumStakeTime) external {
        minimumStakeTime = _minimumStakeTime;
    }
}
