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
} from "../typechain-types";
import { IMessageStruct } from "../typechain-types/contracts/interface/IMessageSpaceStation";
import { ethers } from "hardhat";
import {
  BytesLike,
  AbiCoder,
  keccak256,
  toBeArray,
  EventLog,
  BigNumberish,
} from "ethers";
import { GasMonitor, calculateTxGas } from "../scripts/utils";
import {
  deployMessagePaymentSystem,
  deployMessageSpaceStation,
  deployOmniToken,
} from "../scripts/deployment/utils.deployment";
import { expect } from "chai";

export async function bridgeTransfer(
  token: OmniToken,
  from: HardhatEthersSigner,
  args: {
    destChainId: number;
    receiver: string;
    amount: number;
  }
): Promise<{
  nonce: BigInt;
  params: IMessageStruct.LaunchSingleMsgParamsStruct;
}> {
  const bridgeTransferFee = await token.fetchOmniTokenTransferFee(
    [args.destChainId],
    [args.receiver],
    [args.amount]
  );

  const LaunchPad = new MessageSpaceStation__factory(from).attach(
    await token.LaunchPad()
  );
  let nonce: BigInt = BigInt(0);
  let params: IMessageStruct.LaunchSingleMsgParamsStruct = {} as any;
  LaunchPad.on(
    "SuccessfulLaunchMessage",
    (_nonce: any, _params: IMessageStruct.LaunchSingleMsgParamsStruct) => {
      nonce = _nonce;
      params = _params;
    }
  );

  const tx = await token
    .connect(from)
    .bridgeTransfer(args.destChainId, args.receiver, args.amount, {
      value: bridgeTransferFee * BigInt(2),
    });
  const receipt = await tx.wait();

  if (!params) {
    throw new Error("Failed to get messageId and params");
  }

  let gasMonitor: GasMonitor[] = [];
  gasMonitor.push(await calculateTxGas(tx, "bridgeTransfer", true));
  console.table(gasMonitor);
  console.log(
    "from:",
    await from.getAddress(),
    "to:",
    args.receiver,
    "amount:",
    args.amount
  );

  return { nonce, params };
}

export async function relayerMessage(
  OrbiterStation: MessageSpaceStation,
  relayer: HardhatEthersSigner,
  args: {
    mptRoot: BytesLike;
    aggregatedEarlistArrivalTimestamp: BigNumberish;
    aggregatedLatestArrivalTimestamp: BigNumberish;
    params: IMessageStruct.ParamsLandingStruct[];
  }
) {
  const landInstance = OrbiterStation.connect(relayer).getFunction(
    "Landing(bytes32,uint64,uint64,(uint16,uint24,address,uint256,bytes32,bytes)[])"
  );

  const tx = await landInstance(
    args.mptRoot,
    args.aggregatedEarlistArrivalTimestamp,
    args.aggregatedLatestArrivalTimestamp,
    args.params
  );

  const receipt = await tx.wait();
  let gasMonitor: GasMonitor[] = [];
  gasMonitor.push(await calculateTxGas(tx, "relayerMessage", true));
  console.table(gasMonitor);
}

export async function simulateLanding(
  OrbiterStation: MessageSpaceStation,
  relayer: HardhatEthersSigner,
  params: IMessageStruct.ParamsLandingStruct[]
) {
  const LandingPad: MessageSpaceStation = OrbiterStation.connect(relayer);

  try {
    await LandingPad.SimulateLanding.estimateGas(params);
  } catch (e: any) {
    const error = e.message.match(/SimulateResult\(\[(\w+)\]\)/);
    const result = error[1]
      .split(",")
      .map((v: string) => (v === "true" ? 1 : 0));
    console.log("SimulateLanding result:", result);
  }
}
