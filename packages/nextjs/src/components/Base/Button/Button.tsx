import { CircularLoader } from '../CircularLoader';

interface ButtonProps extends React.HTMLProps<HTMLButtonElement> {
  loading?: boolean;
  type?: 'button' | 'submit';
  variant?: 'primary' | 'secondary' | 'error' | 'text';
  buttonSize?: 'small' | 'medium';
}

export const Button = ({
  children,
  type = 'button',
  variant = 'primary',
  buttonSize = 'medium',
  className = '',
  loading,
  onClick,
  ...rest
}: ButtonProps) => (
  <button
    type={type}
    onClick={onClick}
    className={`btn btn-${variant} btn-${buttonSize} ${className} flex items-center justify-center`}
    {...rest}>
    {loading ? <CircularLoader size="medium" color={variant === 'secondary' ? 'secondary' : 'contrast'} /> : children}
  </button>
);
