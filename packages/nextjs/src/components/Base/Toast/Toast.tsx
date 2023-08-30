import { Dialog } from '@headlessui/react';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import CloseIcon from '@mui/icons-material/Close';
import { useEffect, useState } from 'react';
// TODO: Add variants to this eg. success/error/warning/info
// TODO: Take children rather than text prop?

interface ToastProps {
  transactionHash: string;
  position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left';
  timeout?: number;
}

export const Toast = ({ position = 'top-right', timeout, transactionHash }: ToastProps) => {
  const [isOpen, setIsOpen] = useState(true);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;

    if (timeout) {
      timer = setTimeout(() => setIsOpen(false), timeout);
    }

    return () => {
      if (timeout) {
        clearTimeout(timer);
      }
    };
  }, [timeout]);

  let positionStyles;

  switch (position) {
    case 'top-left':
      positionStyles = 'top-5 left-0 sm:left-5';
      break;
    case 'bottom-right':
      positionStyles = 'bottom-5 right-0 sm:right-5';
      break;
    case 'bottom-left':
      positionStyles = 'bottom-5 left-0 sm:left-5';
      break;
    default:
      positionStyles = 'top-5 right-0 sm:right-5';
  }

  if (!isOpen) {
    return null;
  }

  return (
    <Dialog
      open={isOpen}
      onClose={() => setIsOpen(false)}
      className={`fixed w-full max-w-sm items-center rounded bg-background-success ${positionStyles}`}>
      <Dialog.Panel className="text-text-contrast flex items-center p-4">
        <CheckCircleOutlineIcon sx={{ fontSize: 30, color: '#1e4620', marginRight: 1 }} />
        <Dialog.Description className="text-text-success">
          Transaction was successful..{' '}
          <a
            href={`https://goerli.etherscan.io/tx/${transactionHash}`}
            target="_blank"
            className="block font-semibold underline">
            View details
          </a>
        </Dialog.Description>
        <button type="button" onClick={() => setIsOpen(false)} className="absolute right-1 top-1" aria-label="Close">
          <span className="sr-only">Close</span>
          <CloseIcon sx={{ fontSize: 16, color: '#1e4620' }} />
        </button>
      </Dialog.Panel>
    </Dialog>
  );
};
