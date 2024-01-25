import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  OrbiterStation,
  OrbiterStation__factory,
  IOrbiterStation,
} from "../typechain-types";
import { ethers } from "hardhat";
import { keccak256 } from "ethers";

describe("OrbiterStation", () => {
  let OrbiterStation: OrbiterStation;
  let signers: HardhatEthersSigner[];

  beforeEach(async () => {
    signers = await ethers.getSigners();
    OrbiterStation = await new OrbiterStation__factory(signers[0]).deploy();
    await OrbiterStation.waitForDeployment();

    console.log(
      "OrbiterStation deployed to:",
      await OrbiterStation.getAddress()
    );
  });

  it("Should deploy OrbiterStation", async () => {
    let launchParams: IOrbiterStation.LaunchParamsStruct = {
      destChainld: 1,
      earlistArrivalTime: 1,
      latestArrivalTime: 1,
      sender: await signers[0].getAddress(),
      relayer: await signers[0].getAddress(),
      aditionParams: "0x",
      message: "0x",
    };

    console.log(
      "nonce1:",
      await OrbiterStation.launchNonce(
        launchParams.destChainld,
        launchParams.sender
      )
    );

    const tx = await OrbiterStation.launch(launchParams);
    await tx.wait();

    console.log(
      "nonce2:",
      await OrbiterStation.launchNonce(
        launchParams.destChainld,
        launchParams.sender
      )
    );

    let landParams: IOrbiterStation.LandParamsStruct = {
      scrChainld: 1,
      earlistArrivalTime: 1,
      latestArrivalTime: 1,
      launchNonce: 0,
      sender: await signers[0].getAddress(),
      relayer: await signers[0].getAddress(),
      message: "0x",
    };
    // get random validator signatures
    const validatorSignatures = [keccak256("0x00"), keccak256("0x01")];
    const tx2 = await OrbiterStation.land(validatorSignatures, landParams);
    await tx2.wait();
  });
});
