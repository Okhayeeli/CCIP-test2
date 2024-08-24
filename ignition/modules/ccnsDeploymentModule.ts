import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ccnsDeployment", (m) => {
    //Deploy CCIP Local Simulator
    const ccipSimulator = m.contract("CCIPLocalSimulator", []);

    //Retreive ccip configuration properties from the simulator 
    const chainSelector = m.staticCall(ccipSimulator, "configuration", [], 0, { id: "chainSelector" });
    const sourceRouter = m.staticCall(ccipSimulator, "configuration", [], 1, { id: "sourceRouter" });
    const destinationRouter = m.staticCall(ccipSimulator, "configuration", [], 2, { id: "destinationRouter" });

    //CCNS contracts deployment 
    const ccnsLookupSource = m.contract("CrossChainNameServiceLookup", [], { id: "ccnsLookupSource" });
    const ccnsRegister = m.contract("CrossChainNameServiceRegister", [sourceRouter, ccnsLookupSource], { id: "ccnsRegister" });

    const ccnsLookupReceiver = m.contract("CrossChainNameServiceLookup", [], { id: "DestinationLookup" });
    const ccnsReceiver = m.contract("CrossChainNameServiceReceiver", [destinationRouter, ccnsLookupReceiver, chainSelector], { id: "ccnsReceiver" });
    //
    m.call(ccnsRegister, "enableChain", [chainSelector, ccnsReceiver, 200000]);

    //Set CCNs addresses in the simulator
    m.call(ccnsLookupSource, "setCrossChainNameServiceAddress", [ccnsRegister]);
    m.call(ccnsLookupReceiver, "setCrossChainNameServiceAddress", [ccnsReceiver]);

    return {
        ccipSimulator,
        ccnsLookupSource,
        ccnsRegister,
        ccnsReceiver,
        ccnsLookupReceiver,
    }
});