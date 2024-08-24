// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CrossChainNameServiceLookup} from "contracts/CrossChainNameServiceLookup.sol";
import {CrossChainNameServiceReceiver} from "contracts/CrossChainNameServiceReceiver.sol";
import {CrossChainNameServiceRegister} from "contracts/CrossChainNameServiceRegister.sol";
import {Test, console} from "lib/chainlink-local/lib/forge-std/src/Test.sol";
import {CCIPLocalSimulator} from "lib/chainlink-local/src/ccip/CCIPLocalSimulator.sol";
import {
    IRouterClient, WETH9, LinkToken, BurnMintERC677Helper
} from "lib/chainlink-local/src/ccip/CCIPLocalSimulator.sol";


contract CrossChainNameServiceTest is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    CrossChainNameServiceRegister public ccnsRegister;
    CrossChainNameServiceReceiver public ccnsReceiver;
    CrossChainNameServiceLookup public ccnsLookupSource;
    CrossChainNameServiceLookup public ccnsLookupReceiver;
    
    address public Alice;
    address public owner;
    uint64 public chainSelector;
    IRouterClient public sourceRouter;
    IRouterClient public destinationRouter;

    function setUp() public {
        owner = address(this);
        Alice = makeAddr("Alice");
        ccipLocalSimulator = new CCIPLocalSimulator();
        
        // These Correctly handle the return value of configuration()
        (
            chainSelector,
            sourceRouter,
            destinationRouter,
            ,  // WETH9
            ,  // LinkToken
            ,  // ccipBnM
              // ccipLnM
        ) = ccipLocalSimulator.configuration();

        ccnsLookupSource = new CrossChainNameServiceLookup();
        ccnsLookupReceiver = new CrossChainNameServiceLookup();
        ccnsRegister = new CrossChainNameServiceRegister(address(sourceRouter), address(ccnsLookupSource));
        ccnsReceiver = new CrossChainNameServiceReceiver(address(destinationRouter), address(ccnsLookupReceiver), chainSelector);

        vm.startPrank(owner);
        ccnsLookupSource.setCrossChainNameServiceAddress(address(ccnsRegister));
        ccnsLookupReceiver.setCrossChainNameServiceAddress(address(ccnsReceiver));
        vm.stopPrank();
    }

    function testCrossChainNameServiceSuccess() public {
        vm.startPrank(owner);
        ccnsRegister.enableChain(chainSelector, address(ccnsReceiver), 200000);
        vm.stopPrank();

        ccipLocalSimulator.requestLinkFromFaucet(address(ccnsRegister), 1 ether);
        console.log("LINK requested from faucet");

         // Get the LinkToken  balance
        (,,,, LinkToken linkToken,,) = ccipLocalSimulator.configuration();
        uint256 linkBalance = linkToken.balanceOf(address(ccnsRegister));
        console.log("LINK balance of ccnsRegister:", linkBalance);

        require(linkBalance > 0, "LINK balance is zero");

        vm.prank(Alice);
        ccnsRegister.register("alice.ccns");
        
        address expectedAddress = ccnsLookupSource.lookup("alice.ccns");
        assertEq(expectedAddress, Alice, "Lookup should return Alice's address");
    }
}