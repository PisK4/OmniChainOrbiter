import { ethers, network, upgrades } from "hardhat";
import { getDeployedCreate3Factory, toCREATE3Deploy } from "./CREATE3.utils";
import { TESTERC20UGV1__factory } from "../../typechain-types";
import { assert } from "console";

async function deployTestToken() {
  let implAddress;
  const salt = ethers.encodeBytes32String(`Orbiter_Omini_Protocol_V1.0.E`); // 31 characters that you choose
  const { printNativeCurrencyBalance } = require(`./utils`);
  const [wallet] = await ethers.getSigners();
  console.log(
    `Using network: ${network.name} (${network.config.chainId}), account: ${
      wallet.address
    } having ${await printNativeCurrencyBalance(
      wallet.address
    )} of native currency`
  );

  const initializerArgs = [
    // constructor not used in UUPS contracts. Instead, proxy will call initializer
    wallet.address,
    { x: 10, y: 5 },
  ];

  const cfToken = new TESTERC20UGV1__factory(wallet);
  const nonce = await wallet.getNonce();
  const addressExpectedOfImpl = ethers.getCreateAddress({
    from: wallet.address,
    nonce,
  });
  console.log(
    `Expected address of implementation using nonce ${nonce}: ${addressExpectedOfImpl}`
  );
  implAddress = addressExpectedOfImpl;

  const impl = await cfToken.deploy();
  await impl.waitForDeployment();
  implAddress = await impl.getAddress();
  console.log(
    `implAddress ${
      implAddress === addressExpectedOfImpl ? `matches` : `doesn't match`
    } addressExpectedOfImpl`
  );
  assert(implAddress === addressExpectedOfImpl);

  const proxy = await toCREATE3Deploy(
    cfToken,
    initializerArgs,
    implAddress,
    salt,
    wallet
  ); // Gas cost: 425068

  const proxyAddress = proxy.target;

  // await upgrades.forceImport(proxyAddress, cfToken);
  // console.log(`implementation has been connected with proxy`);
}

deployTestToken().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
