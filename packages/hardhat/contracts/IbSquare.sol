// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Interfaces/superfluid/ISuperfluidToken.sol";
import "./Interfaces/superfluid/ISuperfluid.sol";
import "./Interfaces/superfluid/IConstantFlowAgreementV1.sol";
import "./Interfaces/superfluid/ISquareSuperToken.sol";
import "./Interfaces/superfluid/ISuperfluidResolver.sol";
import "./Interfaces/superfluid/ISuperfluidEndResolver.sol";

import "./SquareERC20Upgradable.sol";

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';


import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import "./mock/interestHelper/Interest.sol";
import {console} from "../lib/forge-std/src/console.sol";


import {CFAv1Library} from "./Interfaces/superfluid/libs/CFAv1Library.sol";


contract IbSquare is Initializable, PausableUpgradeable, SquareERC20Upgradable, AccessControlUpgradeable, UUPSUpgradeable, Interest {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CFAv1Library for CFAv1Library.InitData;

    CFAv1Library.InitData public cfaV1Lib;
    bytes32 public constant CFA_ID =
    keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");

    // variable which grow after any action from user
    // based on current interest rate and time from last update call
    uint256 public growingRatio;

    // time of last ratio update
    uint256 public lastInterestCompound;

    // time limit for using update
    uint256 public updateTimeLimit;

    // constant for ratio calculation
    uint256 private multiplier;

    // interest per second, big number for accurate calculations (10**27)
    uint256 public interestPerSecond;

    // current annual interest rate with 2 decimals
    uint256 public annualInterest;

    // contract that will distribute money between the pool and the wallet
    /// @custom:oz-renamed-from liquidityBuffer
    address public liquidityHandler;

    // flag for upgrades availability
    bool public upgradeStatus;

    // trusted forwarder address, see EIP-2771
    address public trustedForwarder;

    address public exchangeAddress;
    address public superToken;

    address public superfluidResolver;
    address public superfluidEndResolver;

    event TransferAssetValue(
        address indexed from,
        address indexed to,
        uint256 tokenAmount,
        uint256 assetValue,
        uint256 growingRatio
      );

    
    event CreateFlow(
        address indexed from,
        address indexed to,
        int96 amountPerSecond
    );

    event UpdatedFlow(
        address indexed from,
        address indexed to,
        int96 amountPerSecond
    );

    event DeletedFlow(address indexed from, address indexed to);

    event CreateFlowWithTimestamp(
        address indexed from,
        address indexed to,
        int96 amountPerSecond,
        uint256 indexed endTimestamp
    );


    mapping(address => address) public autoInvestMarketToSuperToken;

    uint256 public fiatIndex;

    struct Context {
        uint8 appLevel;
        uint8 callType;
        uint256 timestamp;
        address msgSender;
        bytes4 agreementSelector;
        bytes userData;
        uint256 appAllowanceGranted;
        uint256 appAllowanceWanted;
        int256 appAllowanceUsed;
        address appAddress;
        ISuperfluidToken appAllowanceToken;
    }

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // list of tokens from which deposit available
    EnumerableSetUpgradeable.AddressSet private supportedTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address[] memory _supportedTokens,
        uint256 _interestPerSecond,
        uint256 _annualInterest
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();


        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            supportedTokens.add(_supportedTokens[i]);
        }

        interestPerSecond = _interestPerSecond * 10 ** 10;
        annualInterest = _annualInterest;
        multiplier = 10 ** 18;
        growingRatio = 10 ** 18;
        updateTimeLimit = 60;
        lastInterestCompound = block.timestamp;
    }


    /// @notice  Updates the growingRatio
    /// @dev If more than the updateTimeLimit has passed, call changeRatio from interestHelper to get correct index
    ///      Then update the index and set the lastInterestCompound date.
    function updateRatio() public whenNotPaused {
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            growingRatio = changeRatio(
                growingRatio,
                interestPerSecond,
                lastInterestCompound
            );
            lastInterestCompound = block.timestamp;
        }
    }



    /// @notice  Allows deposits and updates the index, then mints the new appropriate amount.
    /// @dev When called, asset token is sent to the wallet, then the index is updated
    ///      so that the adjusted amount is accurate.
    /// @param _token Deposit token address
    /// @param _amount Amount (with token decimals)
    function deposit(
        address _token,
        uint256 _amount
    ) external returns (uint256 squareMinted) {
        // we assume that the token is already supported
        // user sends the funds to liquidity handler
        IERC20Upgradeable(_token).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        
        uint256 amountIn18 = _amount *
            10 ** (18 - SquareERC20Upgradable(_token).decimals());

        uint256 adjustedAmount = (amountIn18 * multiplier) / growingRatio;

        _mint(_msgSender(), adjustedAmount);

        return adjustedAmount;
    }

    /// @notice  Withdraws accuratel
    /// @dev When called, immediately check for new interest index. Then find the adjusted amount in IbSquare tokens
    ///      Then burn appropriate amount of IbSquare tokens to receive asset token
    /// @param _targetToken Asset token
    /// @param _amount Amount (parsed 10**18) in asset value
    function withdrawTo(
        address _recipient,
        address _targetToken,
        uint256 _amount
    ) public returns (uint256 targetTokenReceived, uint256 ibSquareBurned) {
        uint256 fiatAmount = _amount;
        updateRatio();
        uint256 adjustedAmount = (_amount * multiplier) / growingRatio;

        _burn(_msgSender(), adjustedAmount);
        
        IERC20Upgradeable(_targetToken).transfer(_recipient, _amount);
        return (_amount, adjustedAmount);
    }

    /// @notice  Returns total supply in asset value

    function totalAssetSupply() public view returns (uint256) {
        uint256 _growingRatio = changeRatio(
        growingRatio,
        interestPerSecond,
        lastInterestCompound
        );
        return (totalSupply() * _growingRatio) / multiplier;
    }


    function _authorizeUpgrade(
        address
    ) internal override onlyRole(UPGRADER_ROLE) {
        require(upgradeStatus);
        upgradeStatus = false;
    }

    function setSuperToken(
        address _superToken
      ) external {
        superToken = _superToken;
        ISuperfluid host = ISuperfluid(ISquareSuperToken(superToken).getHost());
        cfaV1Lib = CFAv1Library.InitData(
          host,
          IConstantFlowAgreementV1(address(host.getAgreementClass(CFA_ID)))
        );
      }

    /// @notice  Returns balance in asset value
    /// @param _address address of user
    function getBalance(address _address) public view returns (int256) {
        uint256 _growingRatio = changeRatio(
            growingRatio,
            interestPerSecond,
            lastInterestCompound
        );
        (int256 stIbSquareBalance, , , ) = ISquareSuperToken(superToken)
            .realtimeBalanceOfNow(_address);
        int256 fullBalance = int256(balanceOf(_address)) + stIbSquareBalance;
        return ((fullBalance * int256(_growingRatio)) / int256(multiplier));
    }

    function approveAssetValue(
        address spender,
        uint256 amount
      ) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        updateRatio();
        uint256 adjustedAmount = (amount * multiplier) / growingRatio;
        _approve(owner, spender, adjustedAmount);
        return true;
      }

    
      function transferAssetValue(
        address to,
        uint256 amount
      ) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        updateRatio();
        uint256 adjustedAmount = (amount * multiplier) / growingRatio;
        _transfer(owner, to, adjustedAmount);
        emit TransferAssetValue(owner, to, adjustedAmount, amount, growingRatio);
        return true;
      }

    function withdraw(
        address _targetToken,
        uint256 _amount
      ) external returns (uint256 targetTokenReceived, uint256 ibSquareBurned) {
        return withdrawTo(_msgSender(), _targetToken, _amount);
      }

      function createFlow(
        address receiver,
        int96 flowRate,
        uint256 toWrap
      ) external {
        if (toWrap > 0) {
          _transfer(_msgSender(), address(this), toWrap);
          _approve(address(this), superToken, toWrap);
          ISquareSuperToken(superToken).upgradeTo(_msgSender(), toWrap, "");
        }
    
        address dcaToken = autoInvestMarketToSuperToken[receiver];
        if (
          dcaToken != address(0) &&
          ISquareSuperToken(dcaToken).balanceOf(_msgSender()) == 0
        ) {
          ISquareSuperToken(dcaToken).emitTransfer(_msgSender());
        }
    
        cfaV1Lib.createFlowByOperator(
          _msgSender(),
          receiver,
          ISuperfluidToken(superToken),
          flowRate
        );
        ISuperfluidResolver(superfluidResolver).addToChecker(
          _msgSender(),
          receiver
        );
        emit CreateFlow(_msgSender(), receiver, flowRate);
      }

      function createFlow(
        address receiver,
        int96 flowRate,
        uint256 toWrap,
        uint256 timestamp
      ) external {
        if (toWrap > 0) {
          _transfer(_msgSender(), address(this), toWrap);
          _approve(address(this), superToken, toWrap);
          ISquareSuperToken(superToken).upgradeTo(_msgSender(), toWrap, "");
        }
        address dcaToken = autoInvestMarketToSuperToken[receiver];
        if (
          dcaToken != address(0) &&
          ISquareSuperToken(dcaToken).balanceOf(_msgSender()) == 0
        ) {
          ISquareSuperToken(dcaToken).emitTransfer(_msgSender());
        }
    
        cfaV1Lib.createFlowByOperator(
          _msgSender(),
          receiver,
          ISuperfluidToken(superToken),
          flowRate
        );
        ISuperfluidResolver(superfluidResolver).addToChecker(
          _msgSender(),
          receiver
        );
        ISuperfluidEndResolver(superfluidEndResolver).addToChecker(
          _msgSender(),
          receiver,
          timestamp
        );
        emit CreateFlowWithTimestamp(
          _msgSender(),
          receiver,
          flowRate,
          block.timestamp + timestamp
        );
      }
    
    function deleteFlow(address receiver) external {
        cfaV1Lib.deleteFlowByOperator(
          _msgSender(),
          receiver,
          ISuperfluidToken(superToken)
        );
        ISuperfluidResolver(superfluidResolver).removeFromChecker(
          _msgSender(),
          receiver
        );
        ISuperfluidEndResolver(superfluidEndResolver).removeFromChecker(
          _msgSender(),
          receiver
        );
        emit DeletedFlow(_msgSender(), receiver);
      }

    function updateFlow(
        address receiver,
        int96 flowRate,
        uint256 toWrap
      ) external {
        if (toWrap > 0) {
          _transfer(_msgSender(), address(this), toWrap);
          _approve(address(this), superToken, toWrap);
          ISquareSuperToken(superToken).upgradeTo(_msgSender(), toWrap, "");
        }
        cfaV1Lib.updateFlowByOperator(
          _msgSender(),
          receiver,
          ISuperfluidToken(superToken),
          flowRate
        );
        emit UpdatedFlow(_msgSender(), receiver, flowRate);
      }




    
    function formatPermissions() public view returns (bytes memory) {
        return
          abi.encodeCall(
            cfaV1Lib.cfa.authorizeFlowOperatorWithFullControl,
            (ISuperfluidToken(superToken), address(this), new bytes(0))
          );
      }
    
    function transfer(
        address to,
        uint256 amount
      ) public override whenNotPaused returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
          updateRatio();
        }
        uint256 assetValue = (amount * growingRatio) / multiplier;
        emit TransferAssetValue(owner, to, amount, assetValue, growingRatio);
        return true;
      }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
      ) public override whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
          updateRatio();
        }
        uint256 assetValue = (amount * growingRatio) / multiplier;
        emit TransferAssetValue(from, to, amount, assetValue, growingRatio);
        return true;
      }

    function combinedBalanceOf(address _address) public view returns (int256) {
        (int256 stIbSquareBalance, , , ) = ISquareSuperToken(superToken)
          .realtimeBalanceOfNow(_address);
        return int256(balanceOf(_address)) + stIbSquareBalance;
      }

    function getBalanceForTransfer(
        address _address
      ) public view returns (int256) {
        (int256 stIbSquareBalance, , , ) = ISquareSuperToken(superToken)
          .realtimeBalanceOfNow(_address);
        int256 fullBalance = int256(balanceOf(_address)) + stIbSquareBalance;
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
          uint256 _growingRatio = changeRatio(
            growingRatio,
            interestPerSecond,
            lastInterestCompound
          );
    
          return ((fullBalance * int256(_growingRatio)) / int256(multiplier));
        } else {
          return ((fullBalance * int256(growingRatio)) / int256(multiplier));
        }
      }
    
    function convertToAssetValue(
        uint256 _amountInTokenValue
      ) public view returns (uint256) {
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
          uint256 _growingRatio = changeRatio(
            growingRatio,
            interestPerSecond,
            lastInterestCompound
          );
          return (_amountInTokenValue * _growingRatio) / multiplier;
        } else {
          return (_amountInTokenValue * growingRatio) / multiplier;
        }
      }


      function getListSupportedTokens() public view returns (address[] memory) {
        return supportedTokens.values();
      }
    
      function isTrustedForwarder(
        address forwarder
      ) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
      }


  /* ========== ADMIN CONFIGURATION ========== */

  function mint(
    address account,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _mint(account, amount);
    if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
      updateRatio();
    }
    uint256 assetValue = (amount * growingRatio) / multiplier;
    emit TransferAssetValue(
      address(0),
      _msgSender(),
      amount,
      assetValue,
      growingRatio
    );
  }

  function burn(
    address account,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _burn(account, amount);
    if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
      updateRatio();
    }
    uint256 assetValue = (amount * growingRatio) / multiplier;
    emit TransferAssetValue(
      _msgSender(),
      address(0),
      amount,
      assetValue,
      growingRatio
    );
  }

  function setSuperfluidResolver(
    address _superfluidResolver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    superfluidResolver = _superfluidResolver;
  }

  function setSuperfluidEndResolver(
    address _superfluidEndResolver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    superfluidEndResolver = _superfluidEndResolver;
  }

  function setAutoInvestMarketToSuperToken(
    address[] memory markets,
    address[] memory superTokens
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i; i < markets.length; i++) {
      autoInvestMarketToSuperToken[markets[i]] = superTokens[i];
    }
  }

  /// @notice  Sets the new interest rate
  /// @dev When called, it sets the new interest rate after updating the index.
  /// @param _newAnnualInterest New annual interest rate with 2 decimals 850 == 8.50%
  /// @param _newInterestPerSecond New interest rate = interest per second (100000000244041000*10**10 == 8% APY)

  function setInterest(
    uint256 _newAnnualInterest,
    uint256 _newInterestPerSecond
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 oldAnnualValue = annualInterest;
    uint256 oldValuePerSecond = interestPerSecond;
    updateRatio();
    annualInterest = _newAnnualInterest;
    interestPerSecond = _newInterestPerSecond * 10 ** 10;
  }

  function changeTokenStatus(
    address _token,
    bool _status
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_status) {
      supportedTokens.add(_token);
    } else {
      supportedTokens.remove(_token);
    }
  }

  function setLiquidityHandler(
    address newHandler
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(newHandler.isContract());

    address oldValue = liquidityHandler;
    liquidityHandler = newHandler;
  }

  function setTrustedForwarder(
    address newTrustedForwarder
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    trustedForwarder = newTrustedForwarder;
  }

  function changeUpgradeStatus(
    bool _status
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    upgradeStatus = _status;
  }

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function grantRole(
    bytes32 role,
    address account
  ) public override onlyRole(getRoleAdmin(role)) {
    if (role == DEFAULT_ADMIN_ROLE) {
      require(account.isContract());
    }
    _grantRole(role, account);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    if (amount > balanceOf(from)) {
      ISquareSuperToken(superToken).operatorBurn(
        from,
        amount - balanceOf(from),
        "",
        ""
      );
    }
    super._transfer(from, to, amount);
  }

  function _burn(address account, uint256 amount) internal override {
    // Calculations for superfluid.
    if (amount > balanceOf(account)) {
      ISquareSuperToken(superToken).operatorBurn(
        account,
        amount - balanceOf(account),
        "",
        ""
      );
    }
    super._burn(account, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    super._beforeTokenTransfer(from, to, amount);
  }

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }

}