var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = 'REDACTED';

module.exports = {
  networks: {
    mainnet: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://redacted")
      },
      gas: 4600000,
      network_id: 1
    }
  }
};

// ICO Contract Address: 0x84140d9b5a3127ef8b625c03a2df8b6bec409b62
// GBO Token Address:  0x295e093f47d63258a102ea4bfa69fde4beb4ab2e
