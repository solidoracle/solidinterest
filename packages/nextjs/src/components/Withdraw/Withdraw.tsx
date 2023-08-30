import { Alert } from '../Base/Alert';
import { Button } from '../Base/Button';
import { Toast } from '../Base/Toast';
import { useTokenBalance } from '@/hooks/useTokenBalance';
import { useWithdraw } from '@/hooks/useWithdraw';

export const Withdraw = () => {
  const { tokenBalance } = useTokenBalance();
  const { handleWithdraw, withdrawValue, setWithdrawValue, isWithdrawProcessing, transactionHash } = useWithdraw();
  const insufficientFunds = Number(tokenBalance) < withdrawValue;

  return (
    <>
      {transactionHash && <Toast transactionHash={transactionHash} timeout={5000} />}
      <>
        <form>
          {/* <div className="mb-5 flex w-[100%] gap-4">
            <div className="w-[70%]">
              <label id="withdraw-value">Withdraw amount:</label>
              <div className="mt-2 flex items-end gap-4">
                <input
                  className="input"
                  id="withdraw-value"
                  type="number"
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                    setWithdrawValue(Number(e.target.value));
                  }}
                />
                <p className="text-text-body">IbSquare</p>
              </div>
            </div>
          </div>
          <Divider className="my-6" />
          <div className="mb-10">
            <p className="data">IbSquare Balance: {tokenBalance}</p>
          </div> */}
          <Button
            type="submit"
            variant="primary"
            className="mb-4 w-[100%]"
            loading={isWithdrawProcessing}
            disabled={insufficientFunds || !withdrawValue}
            onClick={e => {
              e.preventDefault();
              handleWithdraw?.();
            }}>
            Withdraw All
          </Button>
        </form>
      </>
      {insufficientFunds && (
        <Alert
          variant="error"
          title="Insufficient Funds"
          description="You have insufficient funds to complete this withdrawal. Please alter the withdraw amount before continuing."
        />
      )}
    </>
  );
};
