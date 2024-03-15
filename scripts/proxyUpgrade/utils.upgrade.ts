import { ethers, network, upgrades } from "hardhat";
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
import { call } from "@openzeppelin/upgrades-core";

async function main(): Promise<void> {
  const [wallet, wallet2] = await ethers.getSigners();

  const oldImplName = "MessageSpaceStationUg";
  const proxyAddress = "0x028Fe2afF4bcaf895FDA43108223fF1D603A4Ab9"; // ERC1967Proxy address

  const contract = await ethers.getContractAt(oldImplName, proxyAddress);

  // Upgrading
  const newImplName = "MessageSpaceStationUgv2";
  const newImpl = await ethers.getContractFactory(newImplName);

  await upgrades.validateUpgrade(contract, newImpl, {
    kind: "uups",
  });

  let implAddress = await upgrades.erc1967.getImplementationAddress(
    proxyAddress
  );

  console.log(
    "Old implementation address:",
    implAddress,
    "proxy address:",
    proxyAddress,
    "version:",
    await contract.Version()
  );

  const upgraded = await upgrades.upgradeProxy(proxyAddress, newImpl, {
    // call: {
    //   fn: "setConfiguration",
    //   args: [ethers.randomBytes(32)],
    // },
  });
  await upgraded.waitForDeployment();

  implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log(
    "New implementation address:",
    implAddress,
    "version:",
    await contract.Version()
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
