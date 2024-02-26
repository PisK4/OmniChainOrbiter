import { ethers, network, upgrades } from "hardhat";
import { printNativeCurrencyBalance } from "./utils";

async function main(): Promise<void> {
  const [wallet, wallet2] = await ethers.getSigners();
  console.log(
    `Using network: ${network.name} (${network.config.chainId}), account: ${
      wallet.address
    } having ${await printNativeCurrencyBalance(
      wallet.address
    )} of native currency`
  );

  const tokenContractName = "TESTERC20UGV1";
  const contractAddress = "0xC7Be52636F68BDaE191a280Aac59A71afEb0200c"; // ERC1967Proxy address

  const contract = await ethers.getContractAt(
    tokenContractName,
    contractAddress
  );

  // await contract.initialize(...constructorArgsOfToken) // 'Initializable: contract is already initialized'

  console.log(`V: ${await contract.getV()}`);

  // Upgrading
  const tokenContractNameV2 = "TESTERC20UGV2";
  const cfTokenV2 = await ethers.getContractFactory(tokenContractNameV2);

  await upgrades.validateUpgrade(contract, cfTokenV2, {
    kind: "uups",
    timeout: 0,
  });

  let implAddress = await upgrades.erc1967.getImplementationAddress(
    contractAddress
  );
  console.log(`Old implementation address: ${implAddress}`);

  const upgraded = await upgrades.upgradeProxy(contractAddress, cfTokenV2);
  console.log(`Upgraded V: ${await upgraded.getV()}`);

  implAddress = await upgrades.erc1967.getImplementationAddress(
    contractAddress
  );
  console.log(`New implementation address: ${implAddress}`);

  // VERIFY ON BLOCKCHAIN EXPLORER
  if (!["hardhat", "localhost"].includes(network.name)) {
    console.log(
      `Waiting to ensure that it will be ready for verification on etherscan...`
    );
    const { setTimeout } = require("timers/promises");
    await setTimeout(20000);
    const { verifyContract } = require("./utils");
    await verifyContract(contractAddress); // proxy. also verifies implementation
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
