/* eslint-disable prettier/prettier */
import hre, { ethers } from "hardhat";

export async function demo() {
  const sourceTxHash =
    "0xee8f7c0561452b09d65e7752a52bed88e343dbb62be4ef9c790bb03416f76800";
  // print tx detail
  const tx = await ethers.provider.getTransactionReceipt(sourceTxHash);
  console.log("tx", tx);
  const blockNumer = tx.blockNumber;
  const blockInfo = await ethers.provider.getBlock(blockNumer);
  // console.log('blockInfo', blockInfo);
  const basefee = blockInfo.baseFeePerGas;
  const priorityFee = tx.effectiveGasPrice?.sub(basefee!).toNumber();
  console.log("priorityFee", priorityFee);
  console.log("timestamp", blockInfo.timestamp);
}

async function main() {
  await demo();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
