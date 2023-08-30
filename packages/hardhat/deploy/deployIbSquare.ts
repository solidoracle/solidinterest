import { BigNumber } from "ethers";
import { ethers, upgrades } from "hardhat";

async function main() {
  const IbSquare = await ethers.getContractFactory("IbSquare");

  const name = "Interest Bearing Square";
  const symbol = "IbSquare";
  const weth = "0xCCB14936C2E000ED8393A571D15A2672537838Ad";
  const supportedTokens = [weth];
  const interestPerSecond = BigNumber.from("100000000470636740");
  const annualInterest = 500;

  const ibSquare = await upgrades.deployProxy(
    IbSquare,
    [name, symbol, supportedTokens, interestPerSecond, annualInterest],
    {
      initializer: "initialize",
      unsafeAllow: ["delegatecall"],
      kind: "uups",
    },
  );

  console.log("IbSquare upgradable deployed to:", ibSquare.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run deploy/deployIbSquare.ts --network goerli
// npx hardhat verify 0x --network polygon
