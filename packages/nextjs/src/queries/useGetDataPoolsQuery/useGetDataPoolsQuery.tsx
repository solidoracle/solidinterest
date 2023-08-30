import { useQuery } from "@tanstack/react-query";
import type { DataPool } from "@/services/aave/getDataPools";
import { getDataPools } from "@/services/aave/getDataPools";

export const useGetDataPoolsQuery = () => {
  return useQuery<DataPool[]>(["getDataPools"], () => getDataPools());
};
