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
} from "../scripts/utils.deployment";
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
  messageId: string;
  params: IMessageSpaceStation.LaunchSingleMsgParamsStruct;
}> {
  const bridgeTransferFee = await token.fetchOmniTokenTransferFee(
    [args.destChainId],
    [args.receiver],
    [args.amount]
  );

  const LaunchPad = new MessageSpaceStation__factory(from).attach(
    await token.LaunchPad()
  );
  let messageId: string = "";
  let params: IMessageSpaceStation.LaunchSingleMsgParamsStruct = {} as any;
  LaunchPad.on(
    "SuccessfulLaunchSingle",
    (
      _messageId: any,
      _params: IMessageSpaceStation.LaunchSingleMsgParamsStruct
    ) => {
      messageId = _messageId;
      params = _params;
    }
  );

  const tx = await token
    .connect(from)
    .bridgeTransfer(args.destChainId, args.receiver, args.amount, {
      value: bridgeTransferFee * BigInt(2),
    });
  const receipt = await tx.wait();

  if (!messageId) {
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

  return { messageId, params };
}

export async function relayerMessage(
  OrbiterStation: MessageSpaceStation,
  relayer: HardhatEthersSigner,
  args: {
    mptRoot: BytesLike;
    aggregatedEarlistArrivalTime: BigNumberish;
    aggregatedLatestArrivalTime: BigNumberish;
    params: IMessageSpaceStation.ParamsLandingStruct[];
  }
) {
  const landInstance = OrbiterStation.connect(relayer).getFunction(
    "Landing(bytes32,uint64,uint64,(uint16,uint24,address,uint256,bytes32,bytes)[])"
  );

  const tx = await landInstance(
    args.mptRoot,
    args.aggregatedEarlistArrivalTime,
    args.aggregatedLatestArrivalTime,
    args.params
  );

  const receipt = await tx.wait();
  let gasMonitor: GasMonitor[] = [];
  gasMonitor.push(await calculateTxGas(tx, "relayerMessage", true));
  console.table(gasMonitor);
}
