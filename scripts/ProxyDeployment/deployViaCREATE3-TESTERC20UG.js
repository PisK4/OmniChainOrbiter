// implementation deployed normally, proxy deployed via CREATE3
const { ethers, network, upgrades } = require(`hardhat`);

// CHOOSE WHICH FACTORY YOU WANT TO USE:
// const factoryToUse = { name: `axelarnetwork`, address: `0xf0d5258610A5eF4ac7b894DDaAD1c314De8d56a5` } // gas cost: 2222365
// const factoryToUse = { name: `ZeframLou`, address: `0x92B9db5453E03E516Fd461a1852E67EAF8Bc6dad` } // gas cost: 2145541
// const factoryToUse = { name: `SKYBITSolady`, address: `0x7008e1DEECA3E45E61b379BBA882134b3A15d9dF` } // gas cost: 2116813
const factoryToUse = {
  name: `SKYBITLite`,
  address: `0xD74C916B09cB7466C8AcF11231610326EC5041DE`,
}; // gas cost: 2117420

const isDeployEnabled = true; // toggle in case you do deployment and verification separately.

const isVerifyEnabled = true;

const useDeployProxy = false; // openzeppelin's deployment script for upgradeable contracts
const useCREATE3 = true;

const salt = ethers.encodeBytes32String(`HAJBIT.ASIA TESTERC20UGV1......`); // 31 characters that you choose

async function main() {
  const {
    rootRequire,
    printNativeCurrencyBalance,
    verifyContract,
  } = require(`./utils`);

  const [wallet, wallet2] = await ethers.getSigners();
  console.log(
    `Using network: ${network.name} (${network.config.chainId}), account: ${
      wallet.address
    } having ${await printNativeCurrencyBalance(
      wallet.address
    )} of native currency, RPC url: ${network.config.url}`
  );

  const tokenContractName = `TESTERC20UGV1`;
  const initializerArgs = [
    // constructor not used in UUPS contracts. Instead, proxy will call initializer
    wallet.address,
    { x: 10, y: 5 },
  ];

  const cfToken = await ethers.getContractFactory(tokenContractName);

  let proxy, proxyAddress, implAddress, initializerData;
  if (useDeployProxy) {
    if (isDeployEnabled) {
      proxy = await upgrades.deployProxy(cfToken, initializerArgs, {
        kind: `uups`,
        timeout: 0,
      });
      await proxy.waitForDeployment();

      proxyAddress = proxy.target;
    }
  } else {
    // not using openzeppelin's script
    const nonce = await wallet.getNonce();
    const addressExpectedOfImpl = ethers.getCreateAddress({
      from: wallet.address,
      nonce,
    });
    console.log(
      `Expected address of implementation using nonce ${nonce}: ${addressExpectedOfImpl}`
    );
    implAddress = addressExpectedOfImpl;

    if (isDeployEnabled) {
      const feeData = await ethers.provider.getFeeData();
      delete feeData.gasPrice;
      const impl = await cfToken.deploy({ ...feeData });
      await impl.waitForDeployment();
      implAddress = await impl.getAddress();
      console.log(
        `implAddress ${
          implAddress === addressExpectedOfImpl ? `matches` : `doesn't match`
        } addressExpectedOfImpl`
      );
    }
    const proxyContractName = `ERC1967Proxy`;
    const cfProxy = await ethers.getContractFactory(proxyContractName); // got the artifacts locally from @openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol. The one in @openzeppelin/upgrades-core is old.
    const fragment = cfToken.interface.getFunction(`initialize`);
    initializerData = cfToken.interface.encodeFunctionData(
      fragment,
      initializerArgs
    );
    const proxyConstructorArgs = [implAddress, initializerData];

    if (useCREATE3) {
      const { getArtifactOfFactory, getDeployedAddress, CREATE3Deploy } =
        rootRequire(`scripts/ProxyDeployment/CREATE3-deploy-functions.js`);

      if (isDeployEnabled) {
        proxy = await CREATE3Deploy(
          factoryToUse.name,
          factoryToUse.address,
          cfProxy,
          proxyContractName,
          proxyConstructorArgs,
          salt,
          wallet
        ); // Gas cost: 425068
        if (proxy === undefined) return;

        proxyAddress = proxy.target;
      } else {
        const artifactOfFactory = getArtifactOfFactory(factoryToUse.name);
        const instanceOfFactory = await ethers.getContractAt(
          artifactOfFactory.abi,
          factoryToUse.address
        );
        const proxyBytecodeWithArgs = (
          await cfProxy.getDeployTransaction(...proxyConstructorArgs)
        ).data;
        proxyAddress = await getDeployedAddress(
          factoryToUse.name,
          instanceOfFactory,
          proxyBytecodeWithArgs,
          wallet,
          salt
        );
      }
    } else {
      // not using CREATE3
      const feeData = await ethers.provider.getFeeData();
      delete feeData.gasPrice;
      proxy = await cfProxy.deploy(implAddress, initializerData, {
        ...feeData,
      });
      await proxy.waitForDeployment();
      proxyAddress = proxy.target;
    }

    if (isDeployEnabled) {
      await upgrades.forceImport(proxyAddress, cfToken);
      console.log(`implementation has been connected with proxy`);
    }
  }
  console.log(`proxy address: ${proxyAddress}`);

  implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log(`implementation address set in proxy: ${implAddress}`);

  // Testing the deployed contract.
  console.log(`Testing:`);
  const deployedContract = await ethers.getContractAt(
    tokenContractName,
    proxyAddress
  );
  console.log(`point: ${await deployedContract.points(wallet.address)}`);
  console.log(`Version: ${await deployedContract.getV()}`);

  // VERIFY ON BLOCKCHAIN EXPLORER
  if (isVerifyEnabled) {
    if (![`hardhat`, `localhost`].includes(network.name)) {
      if (isDeployEnabled) {
        console.log(
          `Waiting to ensure that it will be ready for verification on etherscan...`
        );
        const { setTimeout } = require(`timers/promises`);
        await setTimeout(20000);
      }

      await verifyContract(proxyAddress); // also verifies implementation
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
