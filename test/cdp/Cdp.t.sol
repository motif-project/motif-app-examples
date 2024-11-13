pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT

import {Test, console2} from "forge-std/Test.sol";
import {CDP} from "../../src/cdp/Cdp.sol";
import {IBitcoinPod} from "@bitdsm/interfaces/IBitcoinPod.sol";
import {IAppRegistry} from "@bitdsm/interfaces/IAppRegistry.sol";
import {MockAppRegistry} from "../../src/cdp/mocks/MockAppRegistry.sol";
import {MockBitcoinPod} from "../../src/cdp/mocks/MockBitcoinPod.sol";
import {StableToken} from "../../src/cdp/StableToken.sol";
import {MockOracle} from "../../src/cdp/mocks/MockOracle.sol";
import {MockBitcoinPodManager} from "../../src/cdp/mocks/MockBitcoinPodManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract CdpTest is Test, MockAppRegistry {
    CDP public cdp;
    address public mockBitcoinPod;
    address public mockAppRegistry;
    address public mockBitcoinPodManager;
    address public user;
    address public manager;
    address public priceFeed;
    // StableToken public stableToken;
    MockOracle public oracle;

    // Constants for testing
    uint256 constant INITIAL_BTC_BALANCE_SATS = 100000000;
    uint256 constant INITIAL_BTC_PRICE = 7800000;
    uint256 constant INITIAL_ETH_BALANCE = 100 ether;

    function setUp() public {
        manager = address(0x1);
        user = address(0x2);
        console2.log("user public key", vm.addr(0x2));
        vm.deal(manager, 100 ether);
        vm.deal(user, 100 ether);
        oracle = new MockOracle();
        mockAppRegistry = address(new MockAppRegistry());
        mockBitcoinPodManager = address(new MockBitcoinPodManager());
        priceFeed = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
        cdp = new CDP(mockBitcoinPodManager, address(oracle));
        oracle.updatePrice(priceFeed, 7800000);
        vm.prank(user);
        mockBitcoinPod = MockBitcoinPodManager(mockBitcoinPodManager).createPod(
            manager,
            abi.encodePacked(user)
        );
        MockBitcoinPod(mockBitcoinPod).mint(user, 100000000);
        // Delegate pod to CDP contract
        MockBitcoinPodManager(mockBitcoinPodManager).delegatePod(
            mockBitcoinPod,
            address(cdp)
        );
    }

    function testOpenCDP() public {
        vm.startPrank(user);
        // console2.log("price", oracle.getLatestPrice(priceFeed));
        // console2.log("user", user);
        // console2.log("manager", manager);
        // console2.log("pod address", mockBitcoinPod);
        // console2.log("pod owner", MockBitcoinPod(mockBitcoinPod).owner());
        // console2.log("msg.sender", msg.sender);
        // console2.log("cdp", address(cdp));
        // console2.log("mockBitcoinPodManager", mockBitcoinPodManager);

        // console2.log(
        //     "podToApp",
        //     MockBitcoinPodManager(mockBitcoinPodManager).podToApp(
        //         mockBitcoinPod
        //     )
        // );
        // console2.log(
        //     "userToPod",
        //     MockBitcoinPodManager(mockBitcoinPodManager).userToPod(user)
        // );
        // console2.log(
        //     "is delegated",
        //     MockBitcoinPodManager(mockBitcoinPodManager).podToApp(pod)
        // );
        // vm.warp(block.timestamp + 1 days);
        uint256 collateralAmount = MockBitcoinPod(mockBitcoinPod)
            .getBitcoinBalance();
        // get debt of 5000USD or 500000 cents
        uint256 debtAmount = 500000;

        cdp.openCDP(debtAmount);
        (uint256 collateral, uint256 debt, ) = cdp.getCDP(user);

        uint256 tokenBalance = IERC20(address(cdp.stableToken())).balanceOf(
            user
        );

        assertEq(collateral, collateralAmount);
        assertEq(debt, debtAmount);
        assertEq(tokenBalance, debtAmount);
        assert(MockBitcoinPod(mockBitcoinPod).isLocked());
        vm.stopPrank();
    }

    function testFailOpenCDPWithZeroDebt() public {
        vm.prank(user);
        cdp.openCDP(0);
    }

    function testFailOpenCDPWithUnsafeDebt() public {
        vm.prank(user);
        //  max posible debt is 520000000000000 which is 52000 USD for 1 BTC at 78000.00 USD
        cdp.openCDP(530000000000000);
    }

    function testGenerateDebt() public {
        vm.startPrank(user);
        uint256 debtAmount = 500000;
        cdp.openCDP(debtAmount);
        uint256 newDebt = 200000;
        cdp.generateDebt(newDebt);

        (, uint256 debt, ) = cdp.getCDP(user);
        assertEq(debt, debtAmount + newDebt);
        vm.stopPrank();
    }

    function testRepayDebt() public {
        vm.startPrank(user);
        uint256 debtAmount = 500000;
        cdp.openCDP(debtAmount);
        uint256 repayAmount = 100000;
        cdp.repayDebt(repayAmount);

        (, uint256 debt, ) = cdp.getCDP(user);
        assertEq(debt, 400000);
        vm.stopPrank();
    }

    function testLiquidation() public {
        vm.startPrank(user);
        cdp.openCDP(520000000000000); // Creates an unsafe position
        vm.stopPrank();

        vm.prank(manager);
        oracle.updatePrice(priceFeed, 7000000);
        cdp.liquidate(user);
        (uint256 collateral, uint256 debt, ) = cdp.getCDP(user);
        assertEq(collateral, 0);
        assertEq(debt, 0);
    }

    function testCloseCDP() public {
        vm.startPrank(user);
        cdp.openCDP(500000000);

        cdp.repayDebt(500000000);
        cdp.closeCDP(mockBitcoinPod);
        assert(!MockBitcoinPod(mockBitcoinPod).isLocked());
    }

    function testCollateralRatio() public {
        vm.startPrank(user);
        cdp.openCDP(500000000);
        uint256 collateralRatio = cdp.getCollateralRatio(user);
        assertEq(collateralRatio, 156000000);
    }
}
