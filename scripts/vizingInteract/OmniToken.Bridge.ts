import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { mine, mineUpTo } from "@nomicfoundation/hardhat-network-helpers";
import {
  OmniToken,
  OmniToken__factory,
  MessageSpaceStation,
  MessageSpaceStation__factory,
  ChainA_EncodeMessageDemo,
  ChainA_EncodeMessageDemo__factory,
  IMessageSpaceStation,
  Helper,
  Helper__factory,
  MessagePaymentSystem,
  MessagePaymentSystem__factory,
} from "../../typechain-types";
import { ethers } from "hardhat";

import { calculateTxGas } from "../utils";
import {
  bridgeTransfer,
  relayerMessage,
  simulateLanding,
} from "../../test/utils.methods";
import {
  deployMessagePaymentSystem,
  deployMessageSpaceStation,
  deployOmniToken,
  deployerConfiguatrion,
  getDeployedContracts,
} from "../deployment/utils.deployment";
import { expect } from "chai";
import { deployCreate3Factory } from "../ProxyDeployment/CREATE3.utils";
import { IMessageStruct } from "../../typechain-types/contracts/interface/IMessageSpaceStation";
import { Wallet } from "ethers";

async function main() {
  const deployer = await deployerConfiguatrion();
  const deployedContracts = getDeployedContracts();
  console.log("deployedContracts", deployedContracts);

  // attach to the deployed contracts
  let vizingMessageStation = MessageSpaceStation__factory.connect(
    deployedContracts.OrbiterMessageSpaceStation_Proxy,
    deployer
  );

  const vizingMessageStationAddress = await vizingMessageStation.getAddress();
  console.log(
    "connected to vizingMessageStation at:",
    vizingMessageStationAddress
  );

  let OmniTokenChainA = await deployOmniToken(deployer, {
    name: "Omni Orbiter TokenA",
    symbol: "ORBT-A",
    initialSupply: ethers.utils.parseEther("1000"),
    LaunchPad: vizingMessageStationAddress,
    LandingPad: vizingMessageStationAddress,
    defaultRelayer: await deployer.getAddress(),
  });

  await OmniTokenChainA.setMirrorToken(2, Wallet.createRandom().address);

  setInterval(async () => {
    const { nonce, params } = await bridgeTransfer(OmniTokenChainA, deployer, {
      destChainId: 2,
      receiver: Wallet.createRandom().address,
      amount: 1,
    });
  }, 3000 + Math.random() * 7000);

  while (true) {
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => {
    // exit the script
    process.exit();
  });
