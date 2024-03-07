import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { mine, mineUpTo } from "@nomicfoundation/hardhat-network-helpers";
import {
  OmniToken,
  OmniToken__factory,
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
import {
  bridgeTransfer,
  relayerMessage,
  simulateLanding,
} from "../test/utils.methods";
import {
  deployMessagePaymentSystem,
  deployMessageSpaceStation,
  deployOmniToken,
} from "../scripts/deployment/utils.deployment";
import { expect } from "chai";
import { deployCreate3Factory } from "../scripts/ProxyDeployment/CREATE3.utils";
import { IMessageStruct } from "../typechain-types/contracts/interface/IMessageSpaceStation";

describe("OrbiterStation", () => {
  let OmniTokenChainA: OmniToken;
  let OmniTokenChainB: OmniToken;
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

    OrbiterStationChainA = await deployMessageSpaceStation(
      chainADeployer,
      {
        owner: await chainADeployer.getAddress(),
        paymentSystem: await PaymentSystemChainA.getAddress(),
      },
      true
    );

    OrbiterStationChainB = await deployMessageSpaceStation(
      chainBDeployer,
      {
        owner: await chainBDeployer.getAddress(),
        paymentSystem: await PaymentSystemChainB.getAddress(),
      },
      true
    );

    OmniTokenChainA = await deployOmniToken(chainADeployer, {
      name: "Omni Orbiter TokenA",
      symbol: "ORBT-A",
      initialSupply: 1000,
      LaunchPad: await OrbiterStationChainA.getAddress(),
      LandingPad: await OrbiterStationChainA.getAddress(),
      defaultRelayer: await chainBDeployer.getAddress(),
    });

    OmniTokenChainB = await deployOmniToken(chainBDeployer, {
      name: "Omni Orbiter TokenB",
      symbol: "ORBT-B",
      initialSupply: 1000,
      LaunchPad: await OrbiterStationChainB.getAddress(),
      LandingPad: await OrbiterStationChainB.getAddress(),
      defaultRelayer: await chainBDeployer.getAddress(),
    });

    HelperContract = await new Helper__factory(signers[0]).deploy();
    await HelperContract.waitForDeployment();
  });

  it("test OmniToken has been deployed", async () => {
    const totalSupply = await OmniTokenChainA.totalSupply();
    expect(totalSupply).to.equal(1000);

    const totalSupplyB = await OmniTokenChainB.totalSupply();
    expect(totalSupplyB).to.equal(1000);
  });

  it("test OrbiterStation has been deployed", async () => {
    const owner = await OrbiterStationChainA.owner();
    expect(owner).to.equal(await chainADeployer.getAddress());

    const ownerB = await OrbiterStationChainB.owner();
    expect(ownerB).to.equal(await chainBDeployer.getAddress());
  });

  it("bridge OmniToken from ChainA to ChainB", async () => {
    await OmniTokenChainA.setMirrorToken(2, await OmniTokenChainB.getAddress());
    await OmniTokenChainB.setMirrorToken(1, await OmniTokenChainA.getAddress());

    const { nonce, params } = await bridgeTransfer(
      OmniTokenChainA,
      chainADeployer,
      {
        destChainId: 2,
        receiver: await chainBReceiver.getAddress(),
        amount: 100,
      }
    );

    const LandingParams: IMessageStruct.ParamsLandingStruct = {
      srcChainld: 1,
      nonceLandingCurrent: 0,
      sender: params.sender,
      value: 0,
      messgeId: ethers.keccak256(params.message) as BytesLike,
      message: params.message,
    };

    await mine(600);

    await simulateLanding(OrbiterStationChainB, chainBDeployer, [
      LandingParams,
    ]);

    await relayerMessage(OrbiterStationChainB, chainBDeployer, {
      mptRoot: ethers.keccak256(ethers.randomBytes(32)) as BytesLike,
      aggregatedEarlistArrivalTimestamp: params.earlistArrivalTimestamp,
      aggregatedLatestArrivalTimestamp: params.latestArrivalTimestamp,
      params: [LandingParams],
    });

    const chainADeployerBalance = await OmniTokenChainA.balanceOf(
      await chainADeployer.getAddress()
    );

    const chainATotoalSupply = await OmniTokenChainA.totalSupply();

    const chainBReceiverBalance = await OmniTokenChainB.balanceOf(
      await chainBReceiver.getAddress()
    );

    const chainBTotoalSupply = await OmniTokenChainB.totalSupply();

    console.log(
      "chainADeployerBalance:",
      chainADeployerBalance,
      "chainBReceiverBalance:",
      chainBReceiverBalance,
      "chainATotoalSupply:",
      chainATotoalSupply,
      "chainBTotoalSupply:",
      chainBTotoalSupply,
      "relayerBalance:",
      await OmniTokenChainA.balanceOf(await chainBDeployer.getAddress())
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
    const latestArrivalTimestamp = Math.floor(Date.now() / 1000) + 10000;
    let launchMultiMsgParams: IMessageSpaceStation.launchMultiMsgParamsStruct =
      {
        destChainld: (await ethers.provider.getNetwork()).chainId,
        earlistArrivalTimestamp: 1,
        latestArrivalTimestamp: latestArrivalTimestamp,
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

    let InteractionLanding: IMessageSpaceStation.ParamsLandingStruct = {
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
      Object.values(InteractionLanding)
    );

    const contractencodehash = await HelperContract.encodeparams(
      InteractionLanding
    );

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
      InteractionLanding
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
