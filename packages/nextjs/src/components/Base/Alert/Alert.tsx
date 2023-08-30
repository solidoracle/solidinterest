interface AlertProps extends React.HTMLProps<HTMLDivElement> {
  title: string;
  description: string;
  variant: 'error';
}

export const Alert = ({ title, description, variant }: AlertProps) => {
  return (
    <div
      className={`${variant === 'error' ? 'border border-red-400 bg-red-100 text-red-700' : ''} rounded px-4 py-3`}
      role="alert">
      <p className="mb-2 font-bold">{title}</p>
      <p className="block">{description}</p>
    </div>
  );
};
