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

export const calculateTxGas = async (
  tx: ContractTransactionResponse,
  title?: string,
  getTransactionfee = false,
  index?: number
) => {
  const { maxPriorityFeePerGas } = await ethers.provider.getFeeData();
  const transactionReceipt = await tx.wait();
  // const basefee = baseFeePerGas!.toNumber();
  const gasUsed = transactionReceipt!.gasUsed;
  const gasPrice = tx.gasPrice;
  // const transactionfee = gasUsed * basefee;
  const inputGasUsed = callDataCost(tx.data);
  // const priorityFee = tx.effectiveGasPrice?.sub(basefee).toNumber();
  if (getTransactionfee) {
    console.log(
      title ? title : "gasUsed",
      index ? index : "",
      "total_Gas:",
      gasUsed,
      "excution_Gas",
      gasUsed - inputGasUsed - 21000n,
      "inputData_Gas:",
      inputGasUsed
      // "fee:",
      // transactionfee,
      // "basefee:",
      // basefee
    );
  } else {
    console.log(
      title ? title : "gasUsed",
      index ? index : "",
      "total_Gas:",
      gasUsed,
      // "excution_Gas",
      // gasUsed - inputGasUsed - 21000,
      "inputData_Gas:",
      inputGasUsed
    );
  }
  return {
    gasUsed,
    gasPrice,
    // transactionfee,
  };
};
