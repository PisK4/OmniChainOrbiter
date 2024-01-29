import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  ORBIToken,
  ORBIToken__factory,
  MessageSpaceStation,
  MessageSpaceStation__factory,
  ChainA_EncodeMessageDemo,
  ChainA_EncodeMessageDemo__factory,
  IMessageSpaceStation,
  Helper,
  Helper__factory,
} from "../typechain-types";
import { ethers } from "hardhat";
import { BytesLike, AbiCoder, keccak256, toBeArray, EventLog } from "ethers";
import { calculateTxGas } from "../scripts/utils";

describe("OrbiterStation", () => {
  let OrbiterToken: ORBIToken;
  let OrbiterStation: MessageSpaceStation;
  let signers: HardhatEthersSigner[];
  let DAppDemo: ChainA_EncodeMessageDemo;
  let HelperContract: Helper;

  beforeEach(async () => {
    signers = await ethers.getSigners();
    OrbiterStation = await new MessageSpaceStation__factory(signers[0]).deploy(
      await signers[0].getAddress()
    );
    await OrbiterStation.waitForDeployment();
    console.log(
      "OrbiterStation deployed to:",
      await OrbiterStation.getAddress()
    );

    OrbiterToken = await new ORBIToken__factory(signers[0]).deploy();
    await OrbiterToken.waitForDeployment();
    console.log("OrbiterToken deployed to:", await OrbiterToken.getAddress());

    DAppDemo = await new ChainA_EncodeMessageDemo__factory(signers[2]).deploy();
    await DAppDemo.waitForDeployment();
    console.log("DAppDemo deployed to:", await DAppDemo.getAddress());

    HelperContract = await new Helper__factory(signers[0]).deploy();
    await HelperContract.waitForDeployment();
  });

  it("Should Launch&Land message in OrbiterStation", async () => {
    // build Launch message
    const demo1message = await DAppDemo.buildMessage(
      "0x01",
      await OrbiterToken.getAddress(),
      58000,
      100
    );

    let paramsLaunch: IMessageSpaceStation.ParamsLaunchStruct = {
      destChainld: (await ethers.provider.getNetwork()).chainId,
      earlistArrivalTime: 1,
      latestArrivalTime: 1,
      sender: await signers[0].getAddress(),
      relayer: await signers[0].getAddress(),
      aditionParams: "0x",
      message: demo1message,
    };

    const tx = await OrbiterStation.Launch(paramsLaunch);
    const LaunchTxrecipt = await tx.wait();
    await calculateTxGas(tx, "Launch", true);
    console.log("LaunchID", LaunchTxrecipt!.logs[0].args.messageId);

    console.log(
      "nonce2:",
      await OrbiterStation.nonceLaunch(
        paramsLaunch.destChainld,
        paramsLaunch.sender
      )
    );

    console.log(
      "balance of signer[2] - before:",
      await OrbiterToken.balanceOf(await signers[2].getAddress())
    );

    let paramsLanding: IMessageSpaceStation.ParamsLandingStruct = {
      scrChainld: 1,
      earlistArrivalTime: 1,
      latestArrivalTime: 1,
      nonceLaunch: 0,
      sender: await signers[0].getAddress(),
      relayer: await signers[0].getAddress(),
      value: 0,
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
        paramsLaunch.destChainld,
        paramsLaunch.sender
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

    console.log(
      "balance of signer[2] - after:",
      await OrbiterToken.balanceOf(await signers[2].getAddress())
    );
  });
});
