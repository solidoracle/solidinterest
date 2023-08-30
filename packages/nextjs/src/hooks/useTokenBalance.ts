import { useAccount, useBalance } from 'wagmi';
import { IBSQUARE_TOKEN_ADDRESS } from '@/utils/constants';

export const useTokenBalance = () => {
  const { address } = useAccount();

  const { data: tokenBalance } = useBalance({
    address: address,
    token: IBSQUARE_TOKEN_ADDRESS,
    watch: true,
  });

  return { tokenBalance: tokenBalance?.formatted ? tokenBalance.formatted : '0.000' };
};
