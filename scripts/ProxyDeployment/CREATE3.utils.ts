import { ethers, network, upgrades } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import fs from "fs";
import path from "path";
import { assert } from "console";
import { ContractFactory } from "ethers";

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

  let proxy;
  try {
    proxy = await CREATE3Deploy(
      factoryToUse.name,
      factoryToUse.address,
      cfProxy,
      proxyContractName,
      proxyConstructorArgs,
      salt,
      wallet
    );
    // assert(!proxy);
  } catch (error) {
    console.error(error);
  }
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

const CREATE3Deploy = async (
  factoryToUse: string,
  addressOfFactory: string,
  contractFactory: any,
  contractToDeployName: string,
  constructorArguments: any[],
  salt: string,
  wallet: HardhatEthersSigner
) => {
  const bytecodeWithArgs = (
    await contractFactory.getDeployTransaction(...constructorArguments)
  ).data;

  const artifactOfFactory = getArtifactOfFactory(factoryToUse);
  const instanceOfFactory = await ethers.getContractAt(
    artifactOfFactory.abi,
    addressOfFactory
  );

  const addressExpected = await getDeployedAddress(
    factoryToUse,
    instanceOfFactory,
    bytecodeWithArgs,
    wallet,
    salt
  );
  // console.log(
  //   `Expected address of ${contractToDeployName} using factory at ${addressOfFactory}: ${addressExpected}`
  // );

  if ((await ethers.provider.getCode(addressExpected)) !== `0x`) {
    console.log(
      `The contract already exists at ${addressExpected}. Change the salt if you want to deploy your contract to a different address.`
    );
    const instanceOfDeployedContract = contractFactory.attach(addressExpected);
    return instanceOfDeployedContract;
  }

  const feeData = await ethers.provider.getFeeData();
  const functionCallGasCost = await getGasEstimate(
    factoryToUse,
    instanceOfFactory,
    bytecodeWithArgs,
    wallet,
    salt
  );
  const gasFeeEstimate = feeData.gasPrice! * functionCallGasCost;

  const txResponse = await deploy(
    factoryToUse,
    instanceOfFactory,
    bytecodeWithArgs,
    wallet,
    salt,
    feeData
  );
  await txResponse.wait();

  const instanceOfDeployedContract = contractFactory.attach(addressExpected);

  console.log(
    "Proxy Contract deployed to:",
    instanceOfDeployedContract.target,
    "deploy gasUsed:",
    functionCallGasCost
    // "gasFeeIn:",
    // ethers.formatUnits(gasFeeEstimate, "ether"),
    // "ETH"
  );

  if (instanceOfDeployedContract.target === addressExpected)
    console.log(`The actual deployment address matches the expected address`);

  return instanceOfDeployedContract;
};

const getArtifactOfFactory = (factoryToUse: string) => {
  let savedArtifactFilePath: string;
  switch (factoryToUse) {
    case `ZeframLou`:
      savedArtifactFilePath = `artifacts-saved/@SKYBITDev3/ZeframLou-create3-factory/src/CREATE3Factory.sol/CREATE3Factory.json`;
      break;
    case `axelarnetwork`:
      savedArtifactFilePath = `artifacts-saved/@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol/Create3Deployer.json`;
      break;
    case `SKYBITSolady`:
      savedArtifactFilePath = `artifacts-saved/contracts/SKYBITCREATE3Factory.sol/SKYBITCREATE3Factory.json`;
      break;
    case `SKYBITLite`:
    default:
      return { abi: [] };
  }
  const { rootRequire } = require(`./utils`);
  return rootRequire(savedArtifactFilePath);
};

const getDeployedAddress = async (
  factoryToUse: string,
  instanceOfFactory: any,
  bytecode: string,
  wallet: any,
  salt: string
) => {
  switch (factoryToUse) {
    case `axelarnetwork`:
      return await instanceOfFactory.deployedAddress(
        bytecode,
        wallet.address,
        salt
      );
    case `SKYBITSolady`:
    case `ZeframLou`:
      return await instanceOfFactory.getDeployed(wallet.address, salt);
    case `SKYBITLite`:
    default:
      const { getCreate3Address } = require(`./utils`);
      return await getCreate3Address(
        instanceOfFactory.target,
        wallet.address,
        salt
      );
  }
};

const getGasEstimate = async (
  factoryToUse: string,
  instanceOfFactory: any,
  bytecode: string,
  wallet: HardhatEthersSigner,
  salt: string
) => {
  switch (factoryToUse) {
    case `axelarnetwork`:
      return await instanceOfFactory.deploy.estimateGas(bytecode, salt);
    case `SKYBITSolady`:
    case `ZeframLou`:
      return await instanceOfFactory.deploy.estimateGas(salt, bytecode);
    case `SKYBITLite`:
    default:
      const txData = {
        to: instanceOfFactory.target,
        data: bytecode.replace(`0x`, salt),
      };
      const ret = await wallet.estimateGas(txData);
      return ret;
  }
};

const deploy = async (
  factoryToUse: string,
  instanceOfFactory: any,
  bytecode: string,
  wallet: any,
  salt: string,
  feeData: any
) => {
  delete feeData.gasPrice;

  switch (factoryToUse) {
    case `axelarnetwork`:
      return await instanceOfFactory.deploy(bytecode, salt, { ...feeData });
    case `SKYBITSolady`:
    case `ZeframLou`:
      return await instanceOfFactory.deploy(salt, bytecode, { ...feeData });
    case `SKYBITLite`:
    default:
      const txData = {
        to: instanceOfFactory.target,
        data: bytecode.replace(`0x`, salt),
      };
      return await wallet.sendTransaction(txData, { ...feeData });
  }
};
