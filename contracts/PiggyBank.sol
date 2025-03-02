// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./libraries/Errors.sol";

contract PiggyBank is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // stablecoins on Base blockchain
    IERC20 public constant USDT =
        IERC20(0x323e78f944A9a1FcF3a10efcC5319DBb0bB6e673);
    IERC20 public constant USDC =
        IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e);
    IERC20 public constant DAI =
        IERC20(0xE6F6e27c0BF1a4841E3F09d03D7D31Da8eAd0a27);

    address public developer;
    address public piggyBankOwner;
    string public savingPurpose;
    uint256 public duration;
    uint256 public totalAmntSaved;

    // developer incentive (piggyBank's owner penalty for emergency withdrawal)
    uint16 public constant chargesBps = 1500; // 15% 1,500/10,000 * 100

    // tracking the total amount saved for each token
    mapping(IERC20 => uint256) public totalAmntSavedByTokens;

    mapping(address => bool) hasWithdraw;

    constructor(
        string memory _savingPurpose,
        uint256 _duration,
        address _developer
    ) {
        require(
            _duration > block.timestamp,
            "Duration must be greater than current time"
        );

        savingPurpose = _savingPurpose;
        duration = _duration;
        developer = _developer;

        piggyBankOwner = msg.sender;
        totalAmntSaved = 0;
    }

    // event
    event FundsSaved(
        address indexed sender,
        IERC20 indexed token,
        uint256 amount
    );
    event Withdrawn(
        address indexed sender,
        address indexed reciver,
        IERC20 indexed token,
        uint256 amount
    );
    event EmergencyWithdrawalDone(
        address indexed piggyBankOwner,
        address indexed developer,
        IERC20 indexed token,
        uint256 amountReceiveByOwner,
        uint256 devIncentive
    );

    // modifiers - to check if the user has already withdrawn or not
    modifier isWithdrawn() {
        if (msg.sender != piggyBankOwner) revert Errors.NotOwner(); // validate the bank owner
        if (!hasWithdraw[piggyBankOwner]) revert Errors.AlreadyWithdrawnAll();
        _;
    }

    // save function - to start saving
    function SaveFunds(
        IERC20 _token,
        uint256 _amount
    ) external nonReentrant isWithdrawn {
        if (msg.sender == address(0)) revert Errors.AddressZeroDetected();

        if (_token == USDT || _token == USDC || _token == DAI) {
            IERC20(_token).safeTransferFrom(
                piggyBankOwner,
                address(this),
                _amount
            ); // transfer the funds from piggyBankOwner to Piggy Bank contract

            totalAmntSavedByTokens[_token] += _amount; // track total amount saved by token

            totalAmntSaved += _amount; // update the total amount of usdt, usdc and dai saved by Piggy bank contract
        } else revert Errors.OnlyUSDTDAIandUSDCisAllowed();

        emit FundsSaved(piggyBankOwner, _token, _amount);
    }

    // withdraw function - to withdraw the save funds after the saving period has ended. It will revert if the saving period has not ended
    function withdraw(
        IERC20 _token,
        uint256 _amount
    ) external nonReentrant isWithdrawn {
        if (msg.sender == address(0)) revert Errors.AddressZeroDetected();

        // track the total amount saved for each token
        uint256 tokenTotalBal = totalAmntSavedByTokens[_token];

        // check if saving period has ended
        if (block.timestamp < duration) revert Errors.NotYetTime();

        if (IERC20(_token).balanceOf(address(this)) >= _amount) {
            IERC20(_token).safeTransfer(piggyBankOwner, _amount); // transfer the fund from Piggy Bank contract back to the bankOwner
            tokenTotalBal -= _amount; // update the balance saved by token
            totalAmntSaved -= _amount; // update the total amount saved
        } else revert Errors.NoEnoughBalanceToWithdraw();

        // set isWithdrawn to true, only if the total amount saved has been drained
        if (totalAmntSaved == 0) hasWithdraw[piggyBankOwner] = true;

        emit Withdrawn(address(this), piggyBankOwner, _token, _amount);
    }

    // emergency withdrawal - to withdraw the funds saved before the saving period ends, a 15% fee will be incurred
    function emergencyWithdrawal(IERC20 _token, uint256) external {
        if (msg.sender == address(0)) revert Errors.AddressZeroDetected();

        // track the total amount saved for each token
        uint256 tokenTotalBal = totalAmntSavedByTokens[_token];

        // calculate penalty
        uint256 amountToWithdraw = IERC20(_token).balanceOf(address(this));
        uint256 devIncentive = amountToWithdraw * chargesBps;
        uint256 finalAmntToWithdraw = amountToWithdraw - devIncentive;

        //
        if (amountToWithdraw > 0) {
            IERC20(_token).safeTransfer(developer, devIncentive); // transfer incentive from Piggy Bank contract to the developer
            IERC20(_token).safeTransfer(piggyBankOwner, finalAmntToWithdraw); // transfer the fund from Piggy Bank contract back to the bankOwner
            tokenTotalBal -= amountToWithdraw; // update the balance saved by token
            totalAmntSaved -= amountToWithdraw; // update the total amount saved
        } else revert Errors.NoEnoughBalanceToWithdraw();

        // set isWithdrawn to true, only if the total amount saved has been drained
        if (totalAmntSaved == 0) hasWithdraw[piggyBankOwner] = true;

        emit EmergencyWithdrawalDone(
            address(this),
            piggyBankOwner,
            _token,
            finalAmntToWithdraw,
            devIncentive
        );
    }
}

// Base Network
// 0x323e78f944A9a1FcF3a10efcC5319DBb0bB6e673 usdt
// 0x036CbD53842c5426634e7929541eC2318f3dCF7e usdc
// 0xE6F6e27c0BF1a4841E3F09d03D7D31Da8eAd0a27 dai

