import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PiggyBankFactoryModule = buildModule("PiggyBankFactoryModule", (m) => {
  const piggyBankFactory = m.contract("PiggyBankFactory");

  return { piggyBankFactory };
});

export default PiggyBankFactoryModule;
