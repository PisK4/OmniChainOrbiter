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

  const deploymentData = await new OmniToken__factory(
    signer
  ).getDeployTransaction(
    args.name,
    args.symbol,
    args.initialSupply,
    args.LaunchPad,
    args.LandingPad,
    args.defaultRelayer
  );

  const estimateGas = await signer.estimateGas({
    to: ethers.ZeroAddress,
    data: deploymentData.data,
  });

  console.log(
    "OmniToken",
    args.symbol,
    "deployed to:",
    await OmniToken.getAddress(),
    "deploye gasUsed:",
    estimateGas.toString()
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

  const deploymentData = await new MessageSpaceStation__factory(
    signer
  ).getDeployTransaction(args.owner, args.paymentSystem, 1);

  const estimateGas = await signer.estimateGas({
    to: ethers.ZeroAddress,
    data: deploymentData.data,
  });

  console.log(
    "MessageSpaceStation deployed to:",
    await messageSpaceStation.getAddress(),
    "deploye gasUsed:",
    estimateGas.toString()
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
