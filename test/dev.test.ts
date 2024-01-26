import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  ORBIToken,
  ORBIToken__factory,
  MessageSpaceStation,
  MessageSpaceStation__factory,
  ChainA_EncodeMessageDemo,
  ChainA_EncodeMessageDemo__factory,
  IMessageSpaceStation,
} from "../typechain-types";
import { ethers } from "hardhat";
import { keccak256 } from "ethers";

describe("OrbiterStation", () => {
  let OrbiterToken: ORBIToken;
  let OrbiterStation: MessageSpaceStation;
  let signers: HardhatEthersSigner[];
  let DAppDemo: ChainA_EncodeMessageDemo;

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
  });

  it("Should Launch&Land message in OrbiterStation", async () => {
    // build Launch message
    const demo1message = await DAppDemo.buildMessage(
      "0x01",
      await OrbiterToken.getAddress(),
      58000,
      100
    );

    console.log("demo1message:", demo1message);

    let LaunchParams: IMessageSpaceStation.LaunchParamsStruct = {
      destChainld: 1,
      earlistArrivalTime: 1,
      latestArrivalTime: 1,
      sender: await signers[0].getAddress(),
      relayer: await signers[0].getAddress(),
      aditionParams: "0x",
      message: demo1message,
    };

    console.log(
      "nonce1:",
      await OrbiterStation.launchNonce(
        LaunchParams.destChainld,
        LaunchParams.sender
      )
    );

    const tx = await OrbiterStation.Launch(LaunchParams);
    await tx.wait();

    console.log(
      "nonce2:",
      await OrbiterStation.launchNonce(
        LaunchParams.destChainld,
        LaunchParams.sender
      )
    );

    console.log(
      "balance of signer[2] - before:",
      await OrbiterToken.balanceOf(await signers[2].getAddress())
    );

    let LandParams: IMessageSpaceStation.LandParamsStruct = {
      scrChainld: 1,
      earlistArrivalTime: 1,
      latestArrivalTime: 1,
      launchNonce: 0,
      sender: await signers[0].getAddress(),
      relayer: await signers[0].getAddress(),
      message: demo1message,
    };
    // get random validator signatures
    const validatorSignatures = [keccak256("0x00"), keccak256("0x01")];
    const tx2 = await OrbiterStation.Land(validatorSignatures, LandParams);
    await tx2.wait();

    console.log(
      "balance of signer[2] - after:",
      await OrbiterToken.balanceOf(await signers[2].getAddress())
    );
  });
});
