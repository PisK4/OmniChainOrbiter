import { ethers } from "hardhat";
import {
  BigNumberish,
  ContractTransactionResponse,
  ContractTransaction,
} from "ethers";

export function callDataCost(data: string): bigint {
  return BigInt(
    ethers
      .toBeArray(data)
      .map((x) => (x === 0 ? 4 : 16))
      .reduce((sum, x) => sum + x)
  );
}
export interface GasMonitor {
  action?: string;
  totoalGas: bigint;
  inputDataGas: bigint;
  excutionGas: bigint;
}

export const calculateTxGas = async (
  tx: ContractTransactionResponse,
  title?: string,
  getTransactionfee = false,
  index?: number
): Promise<GasMonitor> => {
  let gasMonitor: GasMonitor = {} as GasMonitor;

  const { maxPriorityFeePerGas } = await ethers.provider.getFeeData();
  const transactionReceipt = await tx.wait();
  // const basefee = baseFeePerGas!.toNumber();
  const gasUsed = transactionReceipt!.gasUsed;
  const gasPrice = tx.gasPrice;
  // const transactionfee = gasUsed * basefee;
  const inputGasUsed = callDataCost(tx.data);
  // const priorityFee = tx.effectiveGasPrice?.sub(basefee).toNumber();
  gasMonitor = {
    action: title?.toString(),
    totoalGas: gasUsed,
    inputDataGas: inputGasUsed,
    excutionGas: gasUsed - inputGasUsed - 21000n,
  };
  return gasMonitor;
};

export async function getCurrentTime() {
  const block = await ethers.provider.getBlock("latest");
  if (block !== null) {
    return block.timestamp;
  }
  return 0;
}
