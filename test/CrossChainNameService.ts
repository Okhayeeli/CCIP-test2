import hre from "hardhat";
import { Contract } from "ethers";
import { strict as assert } from "assert";
import Deployments from "../ignition/modules/ccnsDeploymentModule";


describe("CrossChainNameService", function () {
    let ccnsRegister: Contract;
    let ccnsReceiver: Contract;
    let ccnsLookupSource: Contract;
    let ccnsLookupReceiver: Contract;
    let AliceAddress: string;

    before(async function () {
        // Deploy the contracts using Ignition
        const deployments = await hre.ignition.deploy(Deployments);
        

        // Retrieve deployed contract instances
        ccnsRegister = deployments.ccnsRegister;
        ccnsReceiver = deployments.ccnsReceiver;
        ccnsLookupSource = deployments.ccnsLookupSource;
        ccnsLookupReceiver = deployments.ccnsLookupReceiver;

        // Define Alice's EOA
        const [aliceSigner] = await hre.ethers.getSigners();
        AliceAddress = aliceSigner.address;
    });

    it("should register and lookup alice.ccns", async function () {
        const AliceName = "Alice.ccns";

        // Register the name on the "souce" chain
        const registerTx = await ccnsRegister.register(AliceName);
        await registerTx.wait();

        // Lookup the name on the "destination" chain
        const result = await ccnsLookupReceiver.lookup(AliceName);

        // Assert that the returned address matches Alice's address using Node.js's assert module
        assert.equal(result, AliceAddress, "The lookup address should match Alice's address");
    });
});