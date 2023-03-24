import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Proposal behaviour", () => {
  it("Works as described", async () => {
    const ContractV1 = await ethers.getContractFactory("ContractV1");
    const ContractV2 = await ethers.getContractFactory("ContractV2");
    const ContractV3 = await ethers.getContractFactory("ContractV3");

    const beacon = await upgrades.deployBeacon(ContractV1);
    // Deploy first proxy, currently V1
    const firstProxy = await upgrades.deployBeaconProxy(beacon, ContractV1);
    // Deploy second V1 proxy for later
    const secondProxy = await upgrades.deployBeaconProxy(beacon, ContractV1);

    // Upgrade Beacon to V2, proxies are now out of date
    await upgrades.upgradeBeacon(beacon, ContractV2);

    // Deploy third proxy and echoInt. Passes since it is new and up to date
    const thirdProxy = await await upgrades.deployBeaconProxy(
      beacon,
      ContractV2
    );
    await expect(ContractV2.attach(thirdProxy.address).echoInt()).to.eventually
      .fulfilled;

    // First proxy errors since it hasnt been updated
    await expect(ContractV2.attach(firstProxy.address).echoInt()).to.eventually
      .rejected;

    // Upgrade proxy and echo again, this time it will pass
    await ContractV2.attach(firstProxy.address).upgrade();
    await expect(ContractV2.attach(firstProxy.address).echoInt()).to.eventually
      .fulfilled;

    // Upgrade to V3. Now first and third proxies are V2 and Second proxy is V1
    await upgrades.upgradeBeacon(beacon, ContractV3);

    // EchoString on all should fail
    await expect(ContractV3.attach(firstProxy.address).echoString()).to
      .eventually.rejected;
    await expect(ContractV3.attach(secondProxy.address).echoString()).to
      .eventually.rejected;
    await expect(ContractV3.attach(thirdProxy.address).echoString()).to
      .eventually.rejected;

    // EchoInt should still pass
    await expect(ContractV2.attach(firstProxy.address).echoInt()).to.eventually
      .fulfilled;
    await expect(ContractV2.attach(thirdProxy.address).echoInt()).to.eventually
      .fulfilled;

    // Upgrade second proxy (currently V1). Should correctly be V3 after this
    await ContractV3.attach(secondProxy.address).upgrade();
    await expect(
      ContractV3.attach(secondProxy.address).version()
    ).to.eventually.eq(3);

    // should now pass. upgraded from V1 -> V2 -> V3
    await expect(ContractV3.attach(secondProxy.address).echoString()).to
      .eventually.fulfilled;
  });
});
