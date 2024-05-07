const HDWalletProvider = require("truffle-hdwallet-provider");

// Set your own mnemonic here
const mnemonic = "travel virtual shuffle dial stove worry fog analyst second portion tide stand";
const privat_key = "37510497d10845600349afcf87d1fb9d58c34447ca1446c9895ad9c99fb52661";

module.exports = {
  contracts_directory: './contracts',
  // Object with configuration for each network
  networks: {
    // Configuration for mainnet
    mainnet: {
      provider: function () {
        // Setting the provider with the Infura Mainnet address and Token
        return new HDWalletProvider(privat_key, "https://sepolia.infura.io/v3/9268ce6883654e08892b2eb6219af8f0")
      },
      network_id: "1"
    },
    // Configuration for sepolia network
    sepolia: {
      provider: function () {
        return new HDWalletProvider(privat_key, "https://sepolia.infura.io/v3/9268ce6883654e08892b2eb6219af8f0")
      },
      network_id:"*"
    },
development: {
     host: "127.0.0.1",
     port: 8545,  
     network_id: "*"
   }
  }
};