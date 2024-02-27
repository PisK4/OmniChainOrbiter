import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  BigNumberish,
  ContractTransactionResponse,
  ContractTransaction,
} from "ethers";
import fs from "fs";
import path from "path";
import {
  OmniToken,
  OmniToken__factory,
  MessageSpaceStation,
  MessageSpaceStation__factory,
  MessageSpaceStationUg,
  MessageSpaceStationUg__factory,
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
import { get } from "http";

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
    estimateGas
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

    // console.log(
    //   `Expected implementation:${addressExpectedOfImpl}, using nonce: ${nonce}`
    // );
    implAddress = addressExpectedOfImpl;
    const messageSpaceStationFactory = new MessageSpaceStationUg__factory(
      signer
    );
    const impl = await messageSpaceStationFactory.deploy();

    await impl.waitForDeployment();
    implAddress = await impl.getAddress();

    if (implAddress !== addressExpectedOfImpl) {
      throw new Error(
        `implAddress ${implAddress} doesn't match addressExpectedOfImpl ${addressExpectedOfImpl}`
      );
    }

    const deploymentData = await new MessageSpaceStationUg__factory(
      signer
    ).getDeployTransaction();

    const estimateGas = await signer.estimateGas({
      to: ethers.ZeroAddress,
      data: deploymentData.data,
    });

    console.log(
      "MessageSpaceStation impl deployed to:",
      implAddress,
      "deploy gasUsed:",
      estimateGas
    );

    const initializerArgs = [args.owner, args.paymentSystem, args.owner];

    const proxy = await toCREATE3Deploy(
      messageSpaceStationFactory,
      initializerArgs,
      implAddress,
      ethers.encodeBytes32String(`MessageSpaceStation`),
      signer
    );

    messageSpaceStation = new MessageSpaceStationUg__factory(signer).attach(
      proxy.target
    );

    const deployedContracts = getDeployedContracts();
    deployedContracts.OrbiterMessageSpaceStation_Proxy = proxy.target;
    deployedContracts.OrbiterMessageSpaceStation_Impl = implAddress;
    saveDeployedContracts(deployedContracts);
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
      estimateGas
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

const pathDeployedContracts = path.join(__dirname, "../deployedContracts.json");
const deployedContracts = require(pathDeployedContracts);
export function getDeployedCreate3Factory(): {
  name: string;
  address: string;
} {
  const deployedContracts = getDeployedContracts();
  const CREATE3Factory = {
    name: `SKYBITLite`,
    address: deployedContracts.create3Factory,
  }; // gas cost: 2117420

  return CREATE3Factory;
}

export function getDeployedContracts() {
  if (!fs.existsSync(pathDeployedContracts)) {
    throw new Error("deployedContracts.json doesn't exist");
  } else {
    const contractsString = fs.readFileSync(pathDeployedContracts, "utf8");
    return JSON.parse(contractsString);
  }
}

export function saveDeployedContracts(deployedContracts: any) {
  fs.writeFileSync(
    pathDeployedContracts,
    JSON.stringify(deployedContracts, null, 2)
  );
}
