const MainContract = artifacts.require("MainContract");

module.exports = async function(deployer) {
  const period = 5;
  const usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  await deployer.deploy(MainContract, period, usdt);
};
