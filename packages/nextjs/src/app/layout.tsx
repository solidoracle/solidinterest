'use client';
import '../styles/globals.css';
import { darkTheme, RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Inter } from 'next/font/google';
import Head from 'next/head';
import { useState } from 'react';
import { WagmiConfig } from 'wagmi';
import { chains, config } from '@/services/wagmi';

const inter = Inter({ subsets: ['latin'] });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());

  return (
    <html lang="en">
      <Head>
        <link rel="icon" href="/favicon.ico" />
        <title>SOLIDINTEREST</title>
      </Head>
      <body className={`${inter.className} bg-background-contrast`}>
        <WagmiConfig config={config}>
          <QueryClientProvider client={queryClient}>
            <RainbowKitProvider
              chains={chains}
              theme={darkTheme({
                accentColor: '#fff',
                accentColorForeground: '#000',
              })}>
              {children}
            </RainbowKitProvider>
          </QueryClientProvider>
        </WagmiConfig>
      </body>
    </html>
  );
}
