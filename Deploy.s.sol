// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import { LiquidityPool } from "../src/liquidityPool.sol";  // Adjust to your contract's path
import { simpleErc20 } from "../src/simpleErc20.sol";

contract Deploy is Script {
    function run() external {
        // Set the deployer's private key and start broadcasting
        vm.startBroadcast();
        
        // Assume you have a deployed token address, replace with actual token address
        address tokenAddress = 0xF65F6eC66475F052abD6d1E95Cff26E7E130315c; 
        
        // Deploy the contract, passing the token address
        LiquidityPool pool = new LiquidityPool(tokenAddress);
        
        // Optionally log the deployed address
        console.log("Liquidity Pool deployed at:", address(pool));
        
        // Stop broadcasting the deployment
        vm.stopBroadcast();
    }
}