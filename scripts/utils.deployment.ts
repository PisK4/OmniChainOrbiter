import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  BigNumberish,
  ContractTransactionResponse,
  ContractTransaction,
} from "ethers";

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
} from "../typechain-types";

interface OmniTokenConstructorArgs {
  name: string;
  symbol: string;
  initialSupply: BigNumberish;
  LaunchPad: string;
  LandingPad: string;
  defaultRelayer: string;
}

export async function deployOmniToken(
  signer: HardhatEthersSigner,
  args: OmniTokenConstructorArgs
): Promise<OmniToken> {
  const OmniToken = await new OmniToken__factory(signer).deploy(
    args.name,
    args.symbol,
    args.initialSupply,
    args.LaunchPad,
    args.LandingPad,
    args.defaultRelayer
  );
  await OmniToken.waitForDeployment();

  console.log(
    "OmniToken",
    args.symbol,
    "deployed to:",
    await OmniToken.getAddress()
  );

  return OmniToken;
}

export async function deployMessageSpaceStation(
  signer: HardhatEthersSigner,
  args: { owner: string; paymentSystem: string }
): Promise<MessageSpaceStation> {
  const messageSpaceStation = await new MessageSpaceStation__factory(
    signer
  ).deploy(args.owner, args.paymentSystem, 1);
  await messageSpaceStation.waitForDeployment();

  console.log(
    "MessageSpaceStation deployed to:",
    await messageSpaceStation.getAddress()
  );

  return messageSpaceStation;
}

export async function deployMessagePaymentSystem(
  signer: HardhatEthersSigner
): Promise<MessagePaymentSystem> {
  const messagePaymentSystem = await new MessagePaymentSystem__factory(
    signer
  ).deploy();
  await messagePaymentSystem.waitForDeployment();

  console.log(
    "MessagePaymentSystem deployed to:",
    await messagePaymentSystem.getAddress()
  );

  return messagePaymentSystem;
}
