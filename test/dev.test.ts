import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { mine, mineUpTo } from "@nomicfoundation/hardhat-network-helpers";
import {
  OminiToken,
  OminiToken__factory,
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
import { calculateTxGas } from "../scripts/utils";
import { bridgeTransfer, relayerMessage } from "../test/utils.methods";
import {
  deployMessagePaymentSystem,
  deployMessageSpaceStation,
  deployOminiToken,
} from "../scripts/utils.deployment";
import { expect } from "chai";

describe("OrbiterStation", () => {
  let OminiTokenChainA: OminiToken;
  let OminiTokenChainB: OminiToken;
  let OrbiterStationChainA: MessageSpaceStation;
  let OrbiterStationChainB: MessageSpaceStation;
  let signers: HardhatEthersSigner[];
  let DAppDemo: ChainA_EncodeMessageDemo;
  let HelperContract: Helper;
  let PaymentSystemChainA: MessagePaymentSystem;
  let PaymentSystemChainB: MessagePaymentSystem;
  let chainADeployer: HardhatEthersSigner;
  let chainBDeployer: HardhatEthersSigner;
  let chainAReceiver: HardhatEthersSigner;
  let chainBReceiver: HardhatEthersSigner;

  before(async () => {
    signers = await ethers.getSigners();
    chainADeployer = signers[0];
    chainBDeployer = signers[1];
    chainAReceiver = signers[2];
    chainBReceiver = signers[3];

    PaymentSystemChainA = await deployMessagePaymentSystem(chainADeployer);
    PaymentSystemChainB = await deployMessagePaymentSystem(chainBDeployer);

    OrbiterStationChainA = await deployMessageSpaceStation(chainADeployer, {
      owner: await chainADeployer.getAddress(),
      paymentSystem: await PaymentSystemChainA.getAddress(),
    });

    OrbiterStationChainB = await deployMessageSpaceStation(chainBDeployer, {
      owner: await chainBDeployer.getAddress(),
      paymentSystem: await PaymentSystemChainB.getAddress(),
    });

    OminiTokenChainA = await deployOminiToken(chainADeployer, {
      name: "Omini Orbiter TokenA",
      symbol: "ORBT-A",
      initialSupply: 1000,
      LaunchPad: await OrbiterStationChainA.getAddress(),
      LandingPad: await OrbiterStationChainA.getAddress(),
      defaultRelayer: await chainADeployer.getAddress(),
    });

    OminiTokenChainB = await deployOminiToken(chainBDeployer, {
      name: "Omini Orbiter TokenB",
      symbol: "ORBT-B",
      initialSupply: 1000,
      LaunchPad: await OrbiterStationChainB.getAddress(),
      LandingPad: await OrbiterStationChainB.getAddress(),
      defaultRelayer: await chainADeployer.getAddress(),
    });

    HelperContract = await new Helper__factory(signers[0]).deploy();
    await HelperContract.waitForDeployment();
  });

  it("test OminiToken has been deployed", async () => {
    const totalSupply = await OminiTokenChainA.totalSupply();
    expect(totalSupply).to.equal(1000);

    const totalSupplyB = await OminiTokenChainB.totalSupply();
    expect(totalSupplyB).to.equal(1000);
  });

  it("test OrbiterStation has been deployed", async () => {
    const owner = await OrbiterStationChainA.owner();
    expect(owner).to.equal(await chainADeployer.getAddress());

    const ownerB = await OrbiterStationChainB.owner();
    expect(ownerB).to.equal(await chainBDeployer.getAddress());
  });

  it("bridge OminiToken from ChainA to ChainB", async () => {
    await OminiTokenChainA.setMirrorToken(
      2,
      await OminiTokenChainB.getAddress()
    );
    await OminiTokenChainB.setMirrorToken(
      1,
      await OminiTokenChainA.getAddress()
    );

    const { messageId, params } = await bridgeTransfer(
      OminiTokenChainA,
      chainADeployer,
      {
        destChainId: 2,
        receiver: await chainBReceiver.getAddress(),
        amount: 100,
      }
    );

    const LandingParams: IMessageSpaceStation.ParamsLandingStruct = {
      srcChainld: 1,
      nonceLandingCurrent: 0,
      sender: params.sender,
      value: 0,
      messgeId: messageId,
      message: params.message,
    };

    await mine(600);

    await relayerMessage(OrbiterStationChainB, chainBDeployer, {
      mptRoot: ethers.keccak256(ethers.randomBytes(32)) as BytesLike,
      aggregatedEarlistArrivalTime: params.earlistArrivalTime,
      aggregatedLatestArrivalTime: params.latestArrivalTime,
      params: [LandingParams],
    });

    const chainADeployerBalance = await OminiTokenChainA.balanceOf(
      await chainADeployer.getAddress()
    );

    const chainATotoalSupply = await OminiTokenChainA.totalSupply();

    const chainBReceiverBalance = await OminiTokenChainB.balanceOf(
      await chainBReceiver.getAddress()
    );

    const chainBTotoalSupply = await OminiTokenChainB.totalSupply();

    console.log(
      "chainADeployerBalance:",
      chainADeployerBalance,
      "chainBReceiverBalance:",
      chainBReceiverBalance,
      "chainATotoalSupply:",
      chainATotoalSupply,
      "chainBTotoalSupply:",
      chainBTotoalSupply
    );
  });

  return;

  it("Should Launch&Land message in OrbiterStation", async () => {
    // build Launch message
    const demo1message = await DAppDemo.buildMessage(
      "0x01",
      await OrbiterToken.getAddress(),
      58000,
      100
    );
    const latestArrivalTime = Math.floor(Date.now() / 1000) + 10000;
    let launchMultiMsgParams: IMessageSpaceStation.launchMultiMsgParamsStruct =
      {
        destChainld: (await ethers.provider.getNetwork()).chainId,
        earlistArrivalTime: 1,
        latestArrivalTime: latestArrivalTime,
        sender: await signers[0].getAddress(),
        relayer: await signers[0].getAddress(),
        aditionParams: "0x",
        message: demo1message,
      };

    const tx = await OrbiterStation.Launch(launchMultiMsgParams);
    const LaunchTxrecipt = await tx.wait();
    await calculateTxGas(tx, "Launch", true);
    const messageIdJustLancuhed = LaunchTxrecipt!.logs[0].args.messageId;
    console.log("LaunchID", messageIdJustLancuhed);

    console.log(
      "nonce2:",
      await OrbiterStation.nonceLaunch(
        launchMultiMsgParams.destChainld,
        launchMultiMsgParams.sender
      )
    );

    console.log(
      "balance of signer[2] - before:",
      await OrbiterToken.balanceOf(await signers[2].getAddress())
    );

    let paramsLanding: IMessageSpaceStation.ParamsLandingStruct = {
      srcChainld: 1,
      nonceLandingCurrent: 0,
      sender: await signers[0].getAddress(),
      value: 0,
      messgeId: messageIdJustLancuhed,
      message: demo1message,
    };
    // get random validator signatures

    const ParamsLandingType = [
      "uint64",
      "uint64",
      "uint64",
      "uint24",
      "address",
      "address",
      "uint256",
      "bytes32",
      "bytes",
    ];

    const AbiCoder = ethers.AbiCoder.defaultAbiCoder();

    const encodedParamsLanding = AbiCoder.encode(
      ParamsLandingType,
      Object.values(paramsLanding)
    );

    const contractencodehash = await HelperContract.encodeparams(paramsLanding);

    const encodedParamsLandingHash = ethers.keccak256(encodedParamsLanding);

    console.log(
      "nonce1:",
      await OrbiterStation.nonceLaunch(
        launchMultiMsgParams.destChainld,
        launchMultiMsgParams.sender
      )
    );

    const validatorList = signers.slice(10, 15);
    const validatorAddresses: string[] = [];
    const validatorSignatures: BytesLike[] = [];

    for (const s of validatorList) {
      const signature = await s.signMessage(toBeArray(contractencodehash));
      validatorAddresses.push(await s.getAddress());
      validatorSignatures.push(signature);
    }

    // validatorSignatures.map((s) => {
    //   console.log("signature:", s);
    // });

    // validatorAddresses.map((s) => {
    //   console.log("validatorAddresses:", s);
    // });

    const tx2 = await OrbiterStation.Landing(
      // validatorSignatures,
      ["0x"],
      paramsLanding
    );
    const LandingTxrecipt = await tx2.wait();
    await calculateTxGas(tx2, "Landing", true);
    // const messageIdJustLanding = LandingTxrecipt!.logs[0].args.messageId;
    // console.log("LaunchID", messageIdJustLanding);

    console.log(
      "balance of signer[2] - after:",
      await OrbiterToken.balanceOf(await signers[2].getAddress())
    );
  });
});
