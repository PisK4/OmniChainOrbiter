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
} from "../deployment/utils.deployment";
import { expect } from "chai";
import { deployCreate3Factory } from "../ProxyDeployment/CREATE3.utils";
import { IMessageStruct } from "../../typechain-types/contracts/interface/IMessageSpaceStation";

async function main() {
  let currentProvider = ethers.provider;
  let deployer = await deployerConfiguatrion();

  let PaymentSystemChain: MessagePaymentSystem =
    await deployMessagePaymentSystem(deployer);

  let vizingMessageStation = await deployMessageSpaceStation(deployer, {
    owner: await deployer.getAddress(),
    paymentSystem: await PaymentSystemChain.getAddress(),
  });

  return;
  // if current net work is hardhat, deploy a test token
  if (ethers.provider.network.chainId === 31337) {
    let OmniTokenChainA = await deployOmniToken(deployer, {
      name: "Omni Orbiter TokenA",
      symbol: "ORBT-A",
      initialSupply: 1000,
      LaunchPad: await vizingMessageStation.getAddress(),
      LandingPad: await vizingMessageStation.getAddress(),
      defaultRelayer: await deployer.getAddress(),
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
