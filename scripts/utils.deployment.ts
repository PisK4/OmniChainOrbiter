import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  BigNumberish,
  ContractTransactionResponse,
  ContractTransaction,
} from "ethers";

import {
  OminiToken,
  OminiToken__factory,
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

interface OminiTokenConstructorArgs {
  name: string;
  symbol: string;
  initialSupply: BigNumberish;
  LaunchPad: string;
  LandingPad: string;
  defaultRelayer: string;
}

export async function deployOminiToken(
  signer: HardhatEthersSigner,
  args: OminiTokenConstructorArgs
): Promise<OminiToken> {
  const ominiToken = await new OminiToken__factory(signer).deploy(
    args.name,
    args.symbol,
    args.initialSupply,
    args.LaunchPad,
    args.LandingPad,
    args.defaultRelayer
  );
  await ominiToken.waitForDeployment();

  console.log(
    "OminiToken",
    args.symbol,
    "deployed to:",
    await ominiToken.getAddress()
  );

  return ominiToken;
}

export async function deployMessageSpaceStation(
  signer: HardhatEthersSigner,
  args: { owner: string; paymentSystem: string }
): Promise<MessageSpaceStation> {
  const messageSpaceStation = await new MessageSpaceStation__factory(
    signer
  ).deploy(args.owner, args.paymentSystem);
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
