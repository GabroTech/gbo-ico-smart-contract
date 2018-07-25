const IcoToken = artifacts.require('IcoToken');
const IcoContract = artifacts.require('IcoContract');

module.exports = function(deployer) {
  deployer.deploy(
    IcoToken,
    'Gabro Token',
    'GBO',
    '18',
    '1.0'
  ).then(() => {
    return deployer.deploy(
      IcoContract,
      'redacted', // Your ETH Address
      IcoToken.address,
      '1000000000000000000000000000', // 1,000,000,000 GBO
      '5000', // 1 ETH = 5000 GBO
      '1532091506',//'1532707200', //07/27/2018 @ 4:00pm (UTC)
      '1546272000', // 12/31/2018 @ 4:00pm (UTC)
      '100000000000000000' // Min 0.1 ETH
    ).then(() => {
      return IcoToken.deployed().then(function(instance) {
        return instance.setIcoContract(IcoContract.address);
      });
    });
  });
};
