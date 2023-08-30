import { useState } from 'react';
import { useAccount, useContractWrite, usePrepareContractWrite, useWaitForTransaction } from 'wagmi';
import { IBSQUARE_ABI, IBSQUARE_CONTRACT_ADDRESS } from '@/utils/constants';
import { parseEther } from '@/utils/parseEther';

export const useWithdraw = () => {
  const { address } = useAccount();
  const [withdrawValue, setWithdrawValue] = useState(0);
  const [withdrawHash, setWithdrawHash] = useState('');
  const [transactionHash, setTransactionHash] = useState('');

  const { config: withdrawConfig } = usePrepareContractWrite({
    address: IBSQUARE_CONTRACT_ADDRESS,
    abi: IBSQUARE_ABI,
    functionName: 'withdraw',
    args: [parseEther(withdrawValue), address, address],
  });

  const { write: withdraw } = useContractWrite({
    ...withdrawConfig,
    onSuccess(data: { hash: string }) {
      setWithdrawHash(data.hash);
    },
  });

  const { isLoading: isWithdrawProcessing } = useWaitForTransaction({
    enabled: !!withdrawHash,
    hash: withdrawHash as `0x${string}`,
    onSuccess: data => setTransactionHash(data?.transactionHash),
    // TODO: onError: Show error toast message
  });

  const handleWithdraw = () => {
    withdraw?.();
  };

  return {
    handleWithdraw,
    withdrawValue,
    setWithdrawValue,
    isWithdrawProcessing,
    transactionHash,
  };
};
