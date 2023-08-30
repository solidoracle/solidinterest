import { toBigInt } from 'ethers';
import { useState } from 'react';
import { useAccount, useContractRead, usePrepareContractWrite, useContractWrite, useWaitForTransaction } from 'wagmi';
import { IBSQUARE_CONTRACT_ADDRESS, WETH_ABI, WETH_CONTRACT_ADDRESS } from '@/utils/constants';
import { parseEther } from '@/utils/parseEther';

export const useApprove = () => {
  const [allowance, setAllowance] = useState(toBigInt('0'));
  const [approveAmount, setApproveAmount] = useState(0);
  const { address } = useAccount();
  const [approveHash, setApproveHash] = useState('');

  useContractRead({
    address: WETH_CONTRACT_ADDRESS,
    abi: WETH_ABI,
    functionName: 'allowance',
    args: [address, IBSQUARE_CONTRACT_ADDRESS],
    watch: true,
    onSuccess(data: bigint) {
      setAllowance(data);
    },
  });

  const { config: wethApproveConfig } = usePrepareContractWrite({
    address: WETH_CONTRACT_ADDRESS,
    abi: WETH_ABI,
    functionName: 'approve',
    args: [IBSQUARE_CONTRACT_ADDRESS, parseEther(approveAmount)],
  });

  const { write: wethApprove } = useContractWrite({
    ...wethApproveConfig,
    onSuccess(data: { hash: string }) {
      setApproveHash(data.hash);
    },
  });

  const { isLoading: isApproveProcessing } = useWaitForTransaction({
    enabled: !!approveHash,
    hash: approveHash as `0x${string}`,
    // TODO: onSuccess: Show success toast message
    onSuccess: (data: any) => console.log('completed', data),
    // TODO: onError: Show error toast message
  });

  const approve = (amount: number) => {
    setApproveAmount(amount);
    wethApprove?.();
  };

  return { allowance, approve, setApproveAmount, isApproveProcessing };
};
