import { useAccount, useBalance } from 'wagmi';

export const useEthBalance = () => {
  const { address } = useAccount();
  const { data } = useBalance({
    address: address,
    watch: true,
  });

  return { ethBalance: data?.formatted ? data.formatted : '0.000' };
};
