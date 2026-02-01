import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy('Merchant', {
    from: deployer,
    args: ['0x1DB6990CFAD265EFE4A0BB986488C04CC49FEE53','0xA3A3F5684FA066D9E5520FD5E592D87C322A58C2'], // '0x0997AEB2FB2E15E532B972C145E140B278510143', '0x55DC789DC6D58C596214F10D4A7717E9EC0A8CBB'
    log: true,
  });
};
export default func;
func.tags = ['Merchant'];
