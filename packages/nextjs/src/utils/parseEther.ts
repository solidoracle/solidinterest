import { parseEther as parseEtherUtil } from "viem";

export const parseEther = (value: number) => {
  if (!value || value === 0) {
    return parseEtherUtil("0");
  }
  return parseEtherUtil(value.toString() as `${number}`);
};
