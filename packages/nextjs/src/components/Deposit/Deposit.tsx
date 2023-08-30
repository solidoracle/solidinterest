import { ethers } from 'ethers';
import { useState } from 'react';
import { Button } from '../Base/Button';
import { Divider } from '../Base/Divider';
import { Toast } from '../Base/Toast';
import { Alert } from '@/components/Base/Alert';
import { useApprove } from '@/hooks/useApprove';
import { useDeposit } from '@/hooks/useDeposit';
import { useEthBalance } from '@/hooks/useEthBalance';
import { useWethBalance } from '@/hooks/useWethBalance';
import type { DataPool } from '@/services/aave/getDataPools';

export type CurrencyCode = 'ETH' | 'WETH';
interface DepositProps {
  apy: DataPool['apy'];
}

export const Deposit = ({ apy }: DepositProps) => {
  const { approve, setApproveAmount, allowance, isApproveProcessing } = useApprove();
  const { wethBalance } = useWethBalance();
  const { ethBalance } = useEthBalance();

  const { handleDeposit, depositValue, setDepositValue, isDepositProcessing, transactionHash } = useDeposit();
  const [currencyCode, setCurrencyCode] = useState<CurrencyCode>('ETH');
  const noAllowanceSet = Number(ethers.formatEther(allowance)) === 0;
  const allowanceToLow = Number(depositValue) > Number(ethers.formatEther(allowance));
  const wethSelected = currencyCode === 'WETH';
  const ethSelected = currencyCode === 'ETH';
  const insufficentWeth = wethSelected && depositValue > Number(wethBalance);
  const insufficientEth = ethSelected && depositValue > Number(ethBalance);
  const insufficientFunds = insufficentWeth || insufficientEth;

  return (
    <>
      {transactionHash && <Toast transactionHash={transactionHash} timeout={5000} />}
      <>
        <form>
          <div className="mb-5 flex w-[100%] gap-4">
            <div className="w-[70%]">
              <label id="deposit-value">Deposit amount:</label>
              <input
                id="deposit-value"
                className="input mt-2"
                type="number"
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                  setDepositValue(Number(e.target.value));
                }}
              />
            </div>
            <div className="w-[30%]">
              <label className="text-text-body">Currency:</label>
              <select className="input mt-2" onChange={e => setCurrencyCode(e.target.value as CurrencyCode)}>
                {/* <option value="ETH">ETH</option> */}
                <option value="WETH">WETH</option>
              </select>
            </div>
          </div>
          <Divider className="my-6" />
          <div className="mb-10 flex flex-col justify-between gap-2 text-text-body sm:flex-row">
            <div>
              {wethSelected && <p className="data">Balance: {wethBalance} WETH</p>}
              {ethSelected && <p className="data">Balance: {ethBalance} ETH</p>}
            </div>
            <div>
              <p className="data">{apy}% APY</p>
            </div>
          </div>
          {(wethSelected && noAllowanceSet) || (wethSelected && allowanceToLow) ? (
            <Button
              type="submit"
              variant="secondary"
              className="mb-4 w-[100%]"
              onClick={e => {
                e.preventDefault();
                setApproveAmount(depositValue);
                approve(depositValue);
              }}
              loading={isApproveProcessing}>
              Approve
            </Button>
          ) : (
            <Button
              type="submit"
              variant="primary"
              className="mb-4 w-[100%]"
              onClick={e => {
                e.preventDefault();
                handleDeposit({ currencyCode });
              }}
              disabled={depositValue <= 0 || insufficentWeth || insufficientEth}
              loading={isDepositProcessing}>
              Deposit
            </Button>
          )}
        </form>
      </>
      {insufficientFunds && (
        <Alert
          variant="error"
          title="Insufficient Funds"
          description="You have insufficient funds to complete this deposit. Please increase your funds or alter the deposit amount before continuing."
        />
      )}
    </>
  );
};
