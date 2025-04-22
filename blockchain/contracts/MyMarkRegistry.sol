// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Simple K‑V store:   imageId (bytes32) ➜ fingerprint (bytes32)
 *   • One‑time set (cannot overwrite)
 *   • Public getter auto‑generated
 */
contract MyMarkRegistry {
    mapping(bytes32 => bytes32) public fingerprints;

    event Registered(bytes32 indexed imageId, bytes32 fingerprint);

    function register(bytes32 imageId, bytes32 fingerprint) external {
        require(fingerprints[imageId] == 0x0,
                "Image already registered");
        fingerprints[imageId] = fingerprint;
        emit Registered(imageId, fingerprint);
    }
}