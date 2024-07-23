// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        _mint(msg.sender, 10 ** 9 * 10 ** decimals());
    }
}

contract esRNTToken is ERC20, Ownable {
    constructor() ERC20("esRNT Token", "esRNT") Ownable(msg.sender) {
        _mint(msg.sender, 10 ** 9 * 10 ** decimals());
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

contract StakingPool is Ownable {
    IERC20 public rntToken;
    esRNTToken public esRntToken;

    uint256 public constant REWARD_RATE = 1 ether; // 1 esRNT per RNT per day
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

        Stake storage stakeData = stakes[msg.sender];
        _updateReward(msg.sender);

        rntToken.transferFrom(msg.sender, address(this), _amount);
        stakeData.amount += _amount;
        stakeData.rewardDebt = (stakeData.amount * REWARD_RATE) / 1 days;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        Stake storage stakeData = stakes[msg.sender];
        require(stakeData.amount >= _amount, "Insufficient staked amount");

        _updateReward(msg.sender);

        stakeData.amount -= _amount;
        stakeData.rewardDebt = (stakeData.amount * REWARD_RATE) / 1 days;
        rntToken.transfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() external {
        _updateReward(msg.sender);
    }

    function convertReward(uint256 _amount) external {
        LockedReward storage lockedReward = lockedRewards[msg.sender];
        require(lockedReward.amount >= _amount, "Insufficient locked rewards");

        uint256 burnAmount = (_amount *
            (LOCK_DURATION - (block.timestamp - lockedReward.unlockTime))) /
            LOCK_DURATION;
        uint256 transferAmount = _amount - burnAmount;

        lockedReward.amount -= _amount;
        esRntToken.burn(msg.sender, burnAmount);
        rntToken.transfer(msg.sender, transferAmount);

        emit RewardConverted(msg.sender, transferAmount, burnAmount);
    }

    function _updateReward(address _user) internal {
        Stake storage stakeData = stakes[_user];
        LockedReward storage lockedReward = lockedRewards[_user];

        if (stakeData.amount > 0) {
            uint256 pendingReward = (stakeData.amount *
                REWARD_RATE *
                (block.timestamp - stakeData.lastClaimed)) / 1 days;
            if (pendingReward > 0) {
                esRntToken.transfer(_user, pendingReward);
                lockedReward.amount += pendingReward;
                lockedReward.unlockTime = block.timestamp + LOCK_DURATION;
                stakeData.lastClaimed = block.timestamp;

                emit RewardClaimed(_user, pendingReward);
            }
        }
    }
}
