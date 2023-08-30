import { useAccount, useBalance } from 'wagmi';
import { WETH_CONTRACT_ADDRESS } from '@/utils/constants';

export const useWethBalance = () => {
  const { address } = useAccount();
  const { data } = useBalance({
    address: address,
    token: WETH_CONTRACT_ADDRESS,
    watch: true,
  });

  return { wethBalance: data?.formatted ? data.formatted : '0.000' };
};
