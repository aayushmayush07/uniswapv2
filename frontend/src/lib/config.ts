export const CHAINS = {
    anvil: {
      id: 31337,
      rpcUrl: process.env.NEXT_PUBLIC_RPC_URL_ANVIL!,
    },
    sepolia: {
      id: 11155111,
      rpcUrl: process.env.NEXT_PUBLIC_RPC_URL_SEPOLIA!,
    },
    mainnet: {
      id: 1,
      rpcUrl: process.env.NEXT_PUBLIC_RPC_URL_MAINNET!,
    },
  };
  