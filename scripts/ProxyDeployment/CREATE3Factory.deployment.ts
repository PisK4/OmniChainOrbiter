import { ethers, network, upgrades } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import fs from "fs";
import path from "path";
import { assert } from "console";

const pathDeployedContracts = path.join(__dirname, "../deployedContracts.json");
const deployedContracts = require(pathDeployedContracts);
const factoryToDeploy = `SKYBITLite`;
const isDeployEnabled = true; // toggle in case you do deployment and verification separately.
const isVerifyEnabled = true;

export function getDeployedCreate3Factory(): {
  name: string;
  address: string;
} {
  const pathDeployedContracts = path.join(
    __dirname,
    "../deployedContracts.json"
  );
  const deployedContracts = require(pathDeployedContracts);

  const CREATE3Factory = {
    name: `SKYBITLite`,
    address: deployedContracts.create3Factory,
  }; // gas cost: 2117420

  return CREATE3Factory;
}

export async function toCREATE3Deploy(
  factory: any,
  initializerArgs: any,
  implAddress: string,
  salt: string,
  wallet: HardhatEthersSigner
): Promise<any> {
  const factoryToUse = getDeployedCreate3Factory();
  const {
    rootRequire,
    printNativeCurrencyBalance,
    verifyContract,
  } = require(`./utils`);
  const proxyContractName = `ERC1967Proxy`;
  const cfProxy = await ethers.getContractFactory(proxyContractName); // got the artifacts locally from @openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol. The one in @openzeppelin/upgrades-core is old.
  const fragment = factory.interface.getFunction(`initialize`)!;
  const initializerData = factory.interface.encodeFunctionData(
    fragment,
    initializerArgs
  );
  const proxyConstructorArgs = [implAddress, initializerData];
  const { getArtifactOfFactory, getDeployedAddress, CREATE3Deploy } =
    rootRequire(`scripts/ProxyDeployment/CREATE3-deploy-functions.ts`);

  const proxy = await CREATE3Deploy(
    factoryToUse.name,
    factoryToUse.address,
    cfProxy,
    proxyContractName,
    proxyConstructorArgs,
    salt,
    wallet
  );
  // assert(!proxy);
  await upgrades.forceImport(proxy.target, factory);
  return proxy;
}

export async function deployCreate3Factory(): Promise<void> {
  const [wallet] = await ethers.getSigners();
  const balanceOfWallet = await ethers.provider.getBalance(wallet.address);
  console.log(
    `Using network: ${network.name} (${network.config.chainId}), account: ${
      wallet.address
    } having ${ethers.formatUnits(balanceOfWallet, `ether`)} of native currency`
  );

  const create3FactoryArtifact = getCreate3FactoryArtifact(factoryToDeploy);
  const gasLimit = getGasLimit(factoryToDeploy);

  const { deployKeylessly } = require(`./keyless-deploy-functions`);
  const address = await deployKeylessly(
    create3FactoryArtifact.contractName,
    create3FactoryArtifact.bytecode,
    gasLimit,
    wallet,
    isDeployEnabled
  );

  // VERIFY ON BLOCKCHAIN EXPLORER
  if (
    isVerifyEnabled &&
    factoryToDeploy !== `SKYBITLite` &&
    ![`hardhat`, `localhost`].includes(network.name)
  ) {
    if (isDeployEnabled) {
      console.log(
        `Waiting to ensure that it will be ready for verification on etherscan...`
      );
      const { setTimeout } = require(`timers/promises`);
      await setTimeout(20000);
    }
    const { verifyContract } = require(`./utils`);
    await verifyContract(address, []);
  } else console.log(`Verification on explorer skipped`);
  deployedContracts.create3Factory = address;
  fs.writeFileSync(
    pathDeployedContracts,
    JSON.stringify(deployedContracts, null, 2)
  );
  return address;
}

const getCreate3FactoryArtifact = (factory: string) => {
  let compiledArtifactFilePath;
  switch (
    factory // Get hardhat's compiled artifact file first for comparison with saved copy
  ) {
    case `ZeframLou`:
      compiledArtifactFilePath = `artifacts/@SKYBITDev3/ZeframLou-create3-factory/src/CREATE3Factory.sol/CREATE3Factory.json`;
      break;
    case `axelarnetwork`:
      compiledArtifactFilePath = `artifacts/@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol/Create3Deployer.json`;
      break;
    case `SKYBITSolady`:
      compiledArtifactFilePath = `artifacts/contracts/SKYBITCREATE3Factory.sol/SKYBITCREATE3Factory.json`;
      break;
    case `SKYBITLite`:
    default:
      compiledArtifactFilePath = `artifacts/contracts/Proxy/SKYBITCREATE3FactoryLite.yul/SKYBITCREATE3FactoryLite.json`;
  }

  const { getSavedArtifactFile } = require(`./keyless-deploy-functions`);
  return getSavedArtifactFile(factory, compiledArtifactFilePath);
};

const getGasLimit = (factory: string) => {
  switch (factory) {
    case `ZeframLou`:
      return 500000n; // Gas cost: 388999
    case `axelarnetwork`:
      return 900000n; // Gas cost: 712665
    case `SKYBITSolady`:
      return 350000n; // Gas cost: 247752
    case `SKYBITLite`:
    default:
      return 100000n; // Gas cost: 78914
  }
};

deployCreate3Factory().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
