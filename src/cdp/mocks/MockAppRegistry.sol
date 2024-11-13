// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IAppRegistry} from "@bitdsm/interfaces/IAppRegistry.sol";

contract MockAppRegistry is IAppRegistry {
    mapping(address => AppRegistrationStatus) private registrationStatus;
    mapping(address => string) private metadataURIs;

    function registerApp(address app, bytes memory, bytes32, uint256) external {
        registrationStatus[app] = AppRegistrationStatus.REGISTERED;
        emit AppRegistrationStatusUpdated(
            app,
            AppRegistrationStatus.REGISTERED
        );
    }

    function deregisterApp(address app) external {
        registrationStatus[app] = AppRegistrationStatus.UNREGISTERED;
        emit AppRegistrationStatusUpdated(
            app,
            AppRegistrationStatus.UNREGISTERED
        );
    }

    function isAppRegistered(address app) external view returns (bool) {
        return registrationStatus[app] == AppRegistrationStatus.REGISTERED;
    }

    function cancelSalt(bytes32) external pure {}

    function updateAppMetadataURI(string calldata metadataURI) external {
        metadataURIs[msg.sender] = metadataURI;
        emit AppMetadataURIUpdated(msg.sender, metadataURI);
    }

    // function calculateAppRegistrationDigestHash(
    //     address app,
    //     uint256 nonce
    // ) external pure returns (bytes32) {
    //     // Mock implementation
    //     return keccak256(abi.encodePacked(app, nonce));
    // }
    function calculateAppRegistrationDigestHash(
        address app,
        address appRegistry,
        bytes32 salt,
        uint256 expiry
    ) public view override returns (bytes32) {
        // For mock purposes, you can return a simple hash or even a constant value
        return keccak256(abi.encode(app, appRegistry, salt, expiry));
    }
}
