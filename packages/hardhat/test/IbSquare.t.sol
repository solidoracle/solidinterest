//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/IbSquare.sol";
import "../contracts/StIbSquare.sol";


import { Vm } from 'forge-std/Vm.sol';
import  { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "../contracts/UpgradeUUPS.sol";


interface WETHInterface is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function transfer(address dst, uint256 wad) external returns (bool);
    function approve(address guy, uint256 wad) external returns (bool);

}

contract IbSquareTest is Test {
    UUPSProxy proxy;
    UUPSProxy proxyStreaming;
    StIbSquare stIbSquare;
    StIbSquare stIbSquareProxy;

    IbSquare ibSquare;
    IbSquare ibSquareProxy;
    WETHInterface weth = WETHInterface(0xCCB14936C2E000ED8393A571D15A2672537838Ad); // WETH Goerli
    address owner = address (0x01);

    bytes32 internal constant IMPL_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);


    function setUp() public {
        ibSquare = new IbSquare();
        proxy = new UUPSProxy(address(ibSquare), "");
        ibSquareProxy = IbSquare(address(proxy));

        string memory ibSquareName =  "Interest Bearing Square";
        string memory ibSquareSymbol = "IbSquare";
        // ADD WETH or TEST USDC
        address[] memory supportedTokens = new address[](3);
        supportedTokens[0] = address(weth);
        uint interestPerSecond = 100000000470636740;
        uint annualInterest = 1600;
        
        // multisig already has the admin and upgrader role
        ibSquareProxy.initialize(ibSquareName, ibSquareSymbol, supportedTokens, interestPerSecond, annualInterest);

        string memory StIbSquareName = "Streaming IbSquare USD";
        string memory StIbSquareSymbol = "StIbSquareUSD";
        address superfluidHost = 0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9;

        stIbSquare = new StIbSquare();
        proxyStreaming = new UUPSProxy(address(stIbSquare), "");
        stIbSquareProxy = StIbSquare(address(proxyStreaming));
        
        address[] memory operators = new address[](1);

        operators[0] = address(stIbSquareProxy);

        stIbSquareProxy.squareInitialize(
            address(ibSquareProxy), 
            18,
            StIbSquareName, 
            StIbSquareSymbol, 
            address(superfluidHost), 
            operators );
    
        ibSquareProxy.setSuperToken(address(stIbSquareProxy));

    }

    function test_init() private {
        uint annualInterest = 1600;
        assertEq(ibSquareProxy.annualInterest(), annualInterest);
        assertEq(ibSquareProxy.fiatIndex(), 0);
    }

    function test_e2e() public {
        // weth whale setup
        uint whaleAmount = 1000 ether;


        weth.deposit{value: whaleAmount}();
        assertEq(weth.balanceOf(address(this)), whaleAmount);
        // fill IbSquare with weth
        weth.approve(address(ibSquareProxy), whaleAmount);
        ibSquareProxy.deposit(address(weth), 100 ether);
        weth.approve(address(owner), 10 ether);
        weth.transfer(address(owner), 10 ether);
        assertEq(weth.balanceOf(address(owner)), 10 ether);

        // another user deposits weth
        vm.startPrank(address(owner));
        weth.approve(address(ibSquareProxy), 10 ether);
        ibSquareProxy.deposit(address(weth), 10 ether);

        vm.warp(block.timestamp + 365 days);

        int256 balance = ibSquareProxy.getBalance(address(owner));
        ibSquareProxy.withdraw(address(weth), uint(balance));
        console.log("balance of owner", weth.balanceOf(address(owner)));

    }


}