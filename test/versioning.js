const { expect } = require('chai');
const { ethers, upgrades } = require("hardhat");

describe('Contract Versioning', async () => {
  // TODO test using more than one currency vault
  // TODO test new liquidations (where collateral isn't sent)
  it.only('allows for v2 vaults with versioned vault manager', async () => {
    const [ admin, protocol, user ] = await ethers.getSigners();
    const SEuro = await (await ethers.getContractFactory('SEuroMock')).deploy();
    const ClEthUsd = await (await ethers.getContractFactory('ChainlinkMock')).deploy();
    await ClEthUsd.setPrice(170000000000);
    const TokenManager = await (await ethers.getContractFactory('TokenManager')).deploy(ClEthUsd.address);
    const ClEurUsd = await (await ethers.getContractFactory('ChainlinkMock')).deploy();
    await ClEurUsd.setPrice(106000000);
    const VaultDeployer = await (await ethers.getContractFactory('SmartVaultDeployer')).deploy(ClEurUsd.address);
    const SmartVaultIndex = await (await ethers.getContractFactory('SmartVaultIndex')).deploy();
    const VaultManagerV1 = await upgrades.deployProxy(await ethers.getContractFactory('SmartVaultManager'), [
      120000, 1000, SEuro.address, protocol.address, TokenManager.address,
      VaultDeployer.address, SmartVaultIndex.address
    ]);
    await SEuro.grantRole(await SEuro.DEFAULT_ADMIN_ROLE(), VaultManagerV1.address);

    await VaultManagerV1.connect(user).mint();
    let vaults = await VaultManagerV1.connect(user).vaults();
    let v1Vault = vaults[0];
    expect(v1Vault.status.version).to.equal(1);
    expect(v1Vault.status.vaultType).to.equal(ethers.utils.formatBytes32String('SEURO'));

    // version smart vault manager, to deploy v2 with different vaults
    const VaultDeployerV2 = await (await ethers.getContractFactory('SmartVaultDeployerV2')).deploy(ClEurUsd.address);
    const TokenManagerV2 = await (await ethers.getContractFactory('TokenManager')).deploy(ClEthUsd.address);

    let upgrade = upgrades.upgradeProxy(VaultManagerV1.address,
      await ethers.getContractFactory('SmartVaultManagerV2', user), {
        call: {fn: 'completeUpgrade', args: [120000, 1000, SEuro.address, protocol.address, TokenManagerV2.address,
        VaultDeployerV2.address, SmartVaultIndex.address]}
      }
    );

    await expect(upgrade).to.be.revertedWith('Ownable: caller is not the owner');

    upgrade = upgrades.upgradeProxy(VaultManagerV1.address,
      await ethers.getContractFactory('SmartVaultManagerV2'), {
        call: {fn: 'completeUpgrade', args: [120000, 1000, SEuro.address, protocol.address, TokenManagerV2.address,
        VaultDeployerV2.address, SmartVaultIndex.address]}
      }
    );

    await expect(upgrade).not.to.be.reverted;

    const VaultManagerV2 = await ethers.getContractAt('SmartVaultManagerV2', VaultManagerV1.address);
    expect(await VaultManagerV2.owner()).to.equal(admin.address);
    expect(await VaultManagerV2.ownerOf(1)).to.equal(user.address);

    await VaultManagerV2.connect(user).mint();

    vaults = await VaultManagerV2.connect(user).vaults();
    v1Vault = vaults[0];
    const v2Vault = vaults[1]
    expect(v1Vault.status.version).to.equal(1);
    expect(v1Vault.status.vaultType).to.equal(ethers.utils.formatBytes32String('SEURO'));
    expect(v2Vault.status.version).to.equal(2);
    expect(v2Vault.status.vaultType).to.equal(ethers.utils.formatBytes32String('SEURO'));
  });
});