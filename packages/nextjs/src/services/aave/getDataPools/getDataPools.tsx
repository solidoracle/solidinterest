import axios from 'axios';

export interface DataPool {
  address: string;
  apy: number;
  liquidity: {
    usd: number;
    eth: number;
    native: number;
  };
  name: string;
  price: {
    eth: number;
    usd: number;
  };
  symbol: string;
  updatedAt: string;
}

export const getDataPools = async (): Promise<DataPool[]> => {
  return await axios.get('https://aave-api-v2.aave.com/data/pools').then(res => res.data);
};
