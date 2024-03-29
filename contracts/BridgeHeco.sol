// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./BridgeToken.sol";

contract BridgeHeco {
    address private _admin;
    address private _operator;
    bool private _paused;

    BridgeToken private _hCtxc;
    uint256 public minValue;

    uint256 public checkPoint;

    function initialize(address adminAddr, address operatorAddr) public {
        _admin = adminAddr;
        _operator = operatorAddr;
        _hCtxc = new BridgeToken("hCtxc", "hCtxc");
        _paused = false;
        minValue = 0;
        checkPoint = block.number;
    }

    /**
     * @dev Throws if called by any account other than the administrator.
     */
    modifier onlyAdministrator() {
        require(_admin == msg.sender, "caller is not the administrator");
        _;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "caller is not the operator");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "pasuable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "pauable: unpaused");
        _;
    }

    event DepositToken(address indexed from, address to, uint256 amount);
    event WithdrawToken(
        address indexed to,
        bytes32 indexed taskHash,
        uint256 amount
    );
    event ChangeAdmin(address oldAddress, address newAddress);
    event Paused(address account);
    event Unpasued(address account);

    function depositToken(address to, uint256 amount) public whenNotPaused {
        require(amount >= minValue, "deposit token amount too smaller");
        require(
            _hCtxc.balanceOf(msg.sender) >= amount,
            "now enough token to deposit"
        );
        _hCtxc.burn(msg.sender, amount);
        emit DepositToken(msg.sender, to, amount);
    }

    function withdrawToken(
        address to,
        uint256 amount,
        bytes32 taskHash
    ) external onlyOperator whenNotPaused {
        _hCtxc.mint(to, amount);
        emit WithdrawToken(to, taskHash, amount);
    }

    /**
     * @dev Transfers administration authority of the contract to a new account (`newAdministrator`).
     * Can only be called by the current administrator when paused.
     */
    function changeAdmin(address newAdminAddr)
        public
        onlyAdministrator
        whenPaused
    {
        require(
            newAdminAddr != address(0),
            "new administrator is the zero address"
        );
        address oldAdmin = _admin;
        _admin = newAdminAddr;
        emit ChangeAdmin(oldAdmin, _admin);
    }

    function changeOperator(address newOperatorAddr)
        external
        onlyAdministrator
        whenNotPaused
    {
        require(
            newOperatorAddr != address(0),
            "new operator is the zero address"
        );
        _operator = newOperatorAddr;
    }

    function updateMinValue(uint256 newValue) external onlyAdministrator {
        require(newValue >= 0, "invalid value");
        minValue = newValue;
    }

    function administrator() external view returns (address) {
        return _admin;
    }

    function pause() public onlyAdministrator whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyAdministrator whenPaused {
        _paused = false;
        emit Unpasued(msg.sender);
    }

    function tokenAddress() external view returns (address) {
        return address(_hCtxc);
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    function updateCheckpoint(uint256 newCheckPoint) public onlyOperator {
        require(newCheckPoint > checkPoint, "invalid checkpoint");
        checkPoint = newCheckPoint;
    }
}
