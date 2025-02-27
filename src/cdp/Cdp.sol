// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IOracle.sol";
import "./StableToken.sol";
import {IBitcoinPod} from "@motif-contracts/interfaces/IBitcoinPod.sol";
import {IBitcoinPodManager} from "@motif-contracts/interfaces/IBitcoinPodManager.sol";
import {Constants} from "./Constants.sol";
import {IAppRegistry} from "@motif-contracts/interfaces/IAppRegistry.sol";

contract CDP is ReentrancyGuard, OwnableUpgradeable, IERC1271 {
    // Constants
    uint256 private constant LIQUIDATION_THRESHOLD = 150; // 150% collateralization ratio
    uint256 private constant INTEREST_RATE = 5; // 5% annual interest rate
    uint256 private constant SECONDS_PER_YEAR = 31536000;
    mapping(address => CDPData) public cdps;
    IBitcoinPodManager public bitcoinPodManager;
    StableToken public immutable stableToken;
    IOracle public immutable oracle;

    // Add magic value constants for EIP-1271
    bytes4 internal constant _MAGICVALUE = 0x1626ba7e;
    bytes4 internal constant _INVALID_SIGNATURE = 0xffffffff;

    // CDP state
    struct CDPData {
        uint256 collateralAmount;
        uint256 debtAmount;
        bool isLocked;
        uint256 lastInterestUpdate;
        IBitcoinPod bitcoinPod;
        bool isLiquidated;
    }

    // Events
    event CDPOpened(address indexed owner, uint256 collateral, uint256 debt);
    event CDPClosed(address indexed pod);
    event CollateralAdded(address indexed owner, uint256 amount);
    event CollateralRemoved(address indexed owner, uint256 amount);
    event DebtGenerated(address indexed owner, uint256 amount);
    event DebtRepaid(address indexed owner, uint256 amount);
    event CDPLiquidated(
        address indexed owner,
        uint256 collateral,
        uint256 debt
    );

    constructor(address _bitcoinPodManager, address _oracle) {
        require(_bitcoinPodManager != address(0), "Invalid BitcoinPodManager");
        bitcoinPodManager = IBitcoinPodManager(_bitcoinPodManager);
        stableToken = new StableToken();
        oracle = IOracle(_oracle);
        _transferOwnership(msg.sender);
    }

    // modifier notLiquidated() {
    //     require(!isLiquidated, "CDP is liquidated");
    //     _;
    // }

    modifier onlyPodOwner() {
        // require(
        //     IBitcoinPod(cdps[msg.sender].bitcoinPod).owner() == msg.sender,
        //     "Pod not delegated to CDP Manager"
        // );
        require(
            OwnableUpgradeable(address(cdps[msg.sender].bitcoinPod)).owner() ==
                msg.sender,
            "Pod not delegated to CDP Manager"
        );
        _;
    }

    // ... existing code ...

    function openCDP(uint256 debtAmount) external nonReentrant {
        // require(collateralAmount > 0, "Collateral must be greater than 0");
        require(debtAmount > 0, "Debt must be greater than 0");
        require(cdps[msg.sender].collateralAmount == 0, "CDP already exists");
        // get the pod
        IBitcoinPod bitcoinPod = IBitcoinPod(
            IBitcoinPodManager(bitcoinPodManager).getUserPod(msg.sender)
        );
        // check whether the pod is delegated to this contract
        require(
            bitcoinPodManager.getPodApp(address(bitcoinPod)) == address(this),
            "Pod not delegated to CDP App"
        );
        uint256 collateralAmount = IBitcoinPod(bitcoinPod).getBitcoinBalance();
        uint256 collateralValue = _getCollateralValue(collateralAmount);
        require(
            collateralValue >= (debtAmount * LIQUIDATION_THRESHOLD) / 100,
            "Insufficient collateral"
        );
        address pod = IBitcoinPodManager(bitcoinPodManager).getUserPod(
            msg.sender
        );
        cdps[msg.sender] = CDPData({
            collateralAmount: collateralAmount,
            debtAmount: debtAmount,
            lastInterestUpdate: block.timestamp,
            isLocked: true,
            bitcoinPod: IBitcoinPod(pod),
            isLiquidated: false
        });
        bitcoinPodManager.lockPod(pod);
        stableToken.mint(msg.sender, debtAmount);
        emit CDPOpened(msg.sender, collateralAmount, debtAmount);
    }

    function closeCDP(address pod) external onlyPodOwner nonReentrant {
        CDPData storage cdp = cdps[pod];
        require(!cdp.isLocked, "CDP does not exist");
        require(cdp.debtAmount == 0, "CDP has outstanding debt");

        // Unlock the pod
        bitcoinPodManager.unlockPod(pod);

        // Clear CDP
        delete cdps[pod];

        emit CDPClosed(pod);
    }

    function generateDebt(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        CDPData storage cdp = cdps[msg.sender];
        require(cdp.collateralAmount > 0, "CDP does not exist");

        updateInterest(msg.sender);
        uint256 collateralValue = _getCollateralValue(cdp.collateralAmount);
        require(
            collateralValue >=
                ((cdp.debtAmount + amount) * LIQUIDATION_THRESHOLD) / 100,
            "Would make CDP unsafe"
        );

        cdp.debtAmount += amount;
        stableToken.mint(msg.sender, amount);
        emit DebtGenerated(msg.sender, amount);
    }

    function repayDebt(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        CDPData storage cdp = cdps[msg.sender];
        require(cdp.debtAmount >= amount, "Amount exceeds debt");

        updateInterest(msg.sender);
        cdp.debtAmount -= amount;
        stableToken.burn(msg.sender, amount);
        emit DebtRepaid(msg.sender, amount);
    }

    function liquidate(address owner) external nonReentrant {
        CDPData storage cdp = cdps[owner];
        require(cdp.collateralAmount > 0, "CDP does not exist");

        updateInterest(owner);
        uint256 collateralValue = _getCollateralValue(cdp.collateralAmount);
        require(
            collateralValue < (cdp.debtAmount * LIQUIDATION_THRESHOLD) / 100,
            "CDP is not unsafe"
        );

        emit CDPLiquidated(owner, cdp.collateralAmount, cdp.debtAmount);
        delete cdps[owner];
    }

    function getCollateralRatio(address owner) external view returns (uint256) {
        CDPData storage cdp = cdps[owner];
        if (cdp.debtAmount == 0) return type(uint256).max;
        return
            (_getCollateralValue(cdp.collateralAmount) * 100) / cdp.debtAmount;
    }

    function getCDP(
        address owner
    )
        external
        view
        returns (
            uint256 collateralAmount,
            uint256 debtAmount,
            uint256 lastInterestUpdate
        )
    {
        CDPData storage cdp = cdps[owner];
        return (cdp.collateralAmount, cdp.debtAmount, cdp.lastInterestUpdate);
    }

    // Internal functions
    function _getCollateralValue(
        uint256 amount
    ) internal view returns (uint256) {
        uint256 price = oracle.getLatestPrice(Constants.bitcoinPriceOracle);
        return amount * price;
    }

    function updateInterest(address owner) internal {
        CDPData storage cdp = cdps[owner];
        uint256 timePassed = block.timestamp - cdp.lastInterestUpdate;
        if (timePassed > 0) {
            uint256 interest = (cdp.debtAmount * INTEREST_RATE * timePassed) /
                (SECONDS_PER_YEAR * 100);
            cdp.debtAmount += interest;
            cdp.lastInterestUpdate = block.timestamp;
        }
    }

    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) external view override returns (bytes4) {
        // Recover the signer from the signature
        address signer = ECDSA.recover(_hash, _signature);
        // Check if the signer is the owner
        if (signer == owner()) {
            return _MAGICVALUE;
        }
        return _INVALID_SIGNATURE;
    }
    function updateAppMetadataURI(
        string calldata metadataURI,
        address appRegistry
    ) external {
        // check if app is registered
        require(
            IAppRegistry(appRegistry).isAppRegistered(address(this)),
            "App not registered"
        );
        // update metadataURI
        IAppRegistry(appRegistry).updateAppMetadataURI(metadataURI);
    }
}
