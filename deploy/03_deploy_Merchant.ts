import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy('Merchant', {
    from: deployer,
    args: [], // '0x0997AEB2FB2E15E532B972C145E140B278510143', '0x55DC789DC6D58C596214F10D4A7717E9EC0A8CBB'
    log: true,
  });
};
export default func;
func.tags = ['Merchant'];
