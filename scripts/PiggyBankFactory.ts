import { ethers } from "hardhat";

async function main() {
  const PiggyBankFactory = await ethers.deployContract("PiggyBankFactory");

  await PiggyBankFactory.waitForDeployment();

  console.log({
    "Ticket_City contract successfully deployed to": PiggyBankFactory.target,
  });
}

main().catch((error: any) => {
  console.error(error);
  process.exitCode = 1;
});
