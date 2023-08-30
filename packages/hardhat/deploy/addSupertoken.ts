import { ethers } from "hardhat";

async function main() {
  const ibSquare = await ethers.getContractAt("IbSquare", "0xAe0566A0132F9F220B710570EE8D6897a7964EA3");
  const stIbSquare = "0xe483A5e81d1a7754B89c436c91cB75FDc6af34C6";

  await ibSquare.setSuperToken(stIbSquare);
  console.log("addSupertoken: task complete");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run deploy/addSupertoken.ts --network goerli
