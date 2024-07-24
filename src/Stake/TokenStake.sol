// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RNTToken is ERC20Permit, Ownable {
    constructor()
        ERC20("RNT Token", "RNT")
        ERC20Permit("RNT Token")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 100 * 10 ** 9 * 10 ** decimals());
    }
}

contract esRNTToken is ERC20, Ownable {
    constructor() ERC20("esRNT Token", "esRNT") Ownable(msg.sender) {
        _mint(msg.sender, 100 * 10 ** 9 * 10 ** decimals());
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

contract StakingPool is Ownable {
    IERC20 public rntToken;
    esRNTToken public esRntToken;

    uint256 public constant REWARD_RATE = 1; // 1 esRNT per RNT per day
    uint256 public constant LOCK_DURATION = 30 days;

    struct Stake {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastClaimed;
    }

    struct LockedReward {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Stake) public stakes;
    mapping(address => LockedReward) public lockedRewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardConverted(address indexed user, uint256 amount, uint256 burned);

    constructor(IERC20 _rntToken, esRNTToken _esRntToken) Ownable(msg.sender) {
        rntToken = _rntToken;
        esRntToken = _esRntToken;
    }

    function stakePermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_amount > 0, "Cannot stake 0");

        ERC20Permit(address(rntToken)).permit(
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );

        rntToken.transferFrom(msg.sender, address(this), _amount);

        Stake storage stake = stakes[msg.sender];
        if (stake.amount > 0) {
            uint256 pendingReward = _pendingReward(msg.sender);
            stake.rewardDebt += pendingReward;
        }
        stake.amount += _amount;
        stake.lastClaimed = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount >= _amount, "Insufficient staked amount");

        uint256 pendingReward = _pendingReward(msg.sender);
        stake.rewardDebt += pendingReward;

        stake.amount -= _amount;
        rntToken.transfer(msg.sender, _amount);

        stake.lastClaimed = block.timestamp;
    }

    function claimReward() external {
        uint256 reward = _pendingReward(msg.sender) +
            stakes[msg.sender].rewardDebt;
        stakes[msg.sender].rewardDebt = 0;
        stakes[msg.sender].lastClaimed = block.timestamp;

        lockedRewards[msg.sender] = LockedReward({
            amount: reward,
            unlockTime: block.timestamp + LOCK_DURATION
        });
        esRntToken.transfer(msg.sender, reward);
    }

    function takeReward()
        external
        returns (uint256 rewardAmount, uint256 burnAmount)
    {
        LockedReward storage lockedReward = lockedRewards[msg.sender];
        uint256 unlockTime = lockedReward.unlockTime;
        if (block.timestamp < unlockTime) {
            burnAmount =
                (lockedReward.amount * (unlockTime - block.timestamp)) /
                LOCK_DURATION;
            esRntToken.burn(msg.sender, burnAmount);
        }

        rewardAmount = lockedReward.amount - burnAmount;
        lockedReward.amount = 0;

        rntToken.transfer(msg.sender, rewardAmount);
        // rntToken.transfer(address(0), burnAmount);

        emit RewardConverted(msg.sender, rewardAmount, burnAmount);
    }

    function _pendingReward(address account) internal view returns (uint256) {
        Stake storage stake = stakes[account];
        uint256 stakedDuration = block.timestamp - stake.lastClaimed;
        uint256 pendingReward = (stake.amount * REWARD_RATE * stakedDuration) /
            1 days;
        return pendingReward;
    }
}
