// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface VoteEscrow {
    struct LockedBalance {
        uint amount;
        uint end;
    }
    function modify_lock(uint amount, uint unlock_time) external;
    function increase_amount(uint) external;
    function withdraw() external;
    function locked(address user) external view returns (LockedBalance memory);
}

contract WrappedVEYFI is OwnableUpgradeable, UUPSUpgradeable {
    address public nextVersion;
    address constant public YFI = address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);
    address constant public VEYFI = address(0x90c1f9220d90d3966FbeE24045EDd73E1d588aD5);
    address public controller;

    function initialize() external initializer {
        __Ownable_init();
        IERC20(YFI).approve(VEYFI, type(uint).max);
    }

    function queueUpgrade(address _nextVersion) external onlyOwner {
        nextVersion = _nextVersion;
    }

    function _authorizeUpgrade(address _nextVersion)
        internal
        override
        onlyOwner
    {
        require(nextVersion == _nextVersion, "missmatch");
    }

    function setController(address _controller) external onlyOwner {
        controller = _controller;
    }

    function modifyLock(uint _amount, uint _unlockTime) external {
        require(msg.sender == controller || msg.sender == owner(), "!authorized");
        VoteEscrow(VEYFI).modify_lock(_amount, _unlockTime);
    }
    
    function increaseAmount(uint _value) external {
        require(msg.sender == controller || msg.sender == owner(), "!authorized");
        VoteEscrow(VEYFI).increase_amount(_value);
    }
    
    function withdraw(bool acceptPenalty) external {
        require(msg.sender == controller || msg.sender == owner(), "!authorized");
        uint lockEnd = VoteEscrow(VEYFI).locked(address(this)).end;
        if ((lockEnd > block.timestamp && acceptPenalty) || lockEnd < block.timestamp){
            VoteEscrow(VEYFI).withdraw();
            uint balance = IERC20(YFI).balanceOf(address(this));
            IERC20(YFI).transfer(owner(), balance);
        }
    }

    function execute(address to, uint value, bytes calldata data) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = to.call{value: value}(data);
        
        return (success, result);
    }
}