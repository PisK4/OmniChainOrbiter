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
  MessageSpaceStationUPG,
  MessageSpaceStationUPG__factory,
  ChainA_EncodeMessageDemo,
  ChainA_EncodeMessageDemo__factory,
  IMessageSpaceStation,
  Helper,
  Helper__factory,
  MessagePaymentSystem,
  MessagePaymentSystem__factory,
  TESTERC20UGV1__factory,
} from "../../typechain-types";
import { toCREATE3Deploy } from "../ProxyDeployment/CREATE3.utils";

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
    "deploy gasUsed:",
    estimateGas.toString()
  );

  return OmniToken;
}

export async function deployMessageSpaceStation(
  signer: HardhatEthersSigner,
  args: { owner: string; paymentSystem: string },
  isUpgradable: boolean = true
): Promise<MessageSpaceStation> {
  let messageSpaceStation: any;

  if (isUpgradable) {
    let implAddress;
    const nonce = await signer.getNonce();
    const addressExpectedOfImpl = ethers.getCreateAddress({
      from: signer.address,
      nonce,
    });

    console.log(
      `Expected address of implementation using nonce ${nonce}: ${addressExpectedOfImpl}`
    );
    implAddress = addressExpectedOfImpl;
    const messageSpaceStationFactory = new MessageSpaceStationUPG__factory(
      signer
    );
    const impl = await messageSpaceStationFactory.deploy();

    await impl.waitForDeployment();
    implAddress = await impl.getAddress();
    console.log(
      `implAddress ${
        implAddress === addressExpectedOfImpl ? `matches` : `doesn't match`
      } addressExpectedOfImpl`
    );

    const initializerArgs = [
      args.owner,
      args.paymentSystem,
      args.owner,
      args.owner,
    ];

    const proxy = await toCREATE3Deploy(
      messageSpaceStationFactory,
      initializerArgs,
      implAddress,
      ethers.encodeBytes32String(`MessageSpaceStation`),
      signer
    );

    messageSpaceStation = new MessageSpaceStationUPG__factory(signer).attach(
      proxy.target
    );
  } else {
    messageSpaceStation = await new MessageSpaceStation__factory(signer).deploy(
      args.owner,
      args.paymentSystem,
      1
    );

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
      "deploy gasUsed:",
      estimateGas.toString()
    );
  }

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
