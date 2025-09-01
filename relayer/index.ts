import fs from "fs";
import path from "path";
import { ethers } from "ethers";
import BridgeAbi from "../out/Bridge.sol/Bridge.json";
import "dotenv/config";

function getLatestDeployment(chainId: number) {
  const filePath = path.join(
    __dirname,
    `../broadcast/DeployBridge.s.sol/${chainId}/run-latest.json`
  );
  const raw = fs.readFileSync(filePath, "utf-8");
  const json = JSON.parse(raw);
  const tx = json.transactions.find((t: any) => t.transactionType === "CREATE");
  if (!tx) throw new Error("No CREATE transaction in broadcast file");
  return tx.contractAddress;
}

const ETH_RPC = process.env.ETH_MAINNET_SANDBOX!;
const POL_RPC = process.env.POL_MAINNET_SANDBOX!;
const PK = process.env.PRIVATE_KEY!;

// cross-chain token mapping
const TOKEN_MAP: Record<string, string> = {
  [process.env.ETH_USDT_TOKEN!]: process.env.POL_USDT_TOKEN!,
  [process.env.ETH_WETH_TOKEN!]: process.env.POL_WETH_TOKEN!,
  [process.env.POL_USDT_TOKEN!]: process.env.ETH_USDT_TOKEN!,
  [process.env.POL_WETH_TOKEN!]: process.env.ETH_WETH_TOKEN!,
};

async function main() {
  const ethProvider = new ethers.JsonRpcProvider(ETH_RPC);
  const polProvider = new ethers.JsonRpcProvider(POL_RPC);
  const wallet = new ethers.Wallet(PK, polProvider);

  const ethBridgeAddr = getLatestDeployment(1);
  const polBridgeAddr = getLatestDeployment(137);

  console.log("ETH Bridge:", ethBridgeAddr);
  console.log("POL Bridge:", polBridgeAddr);

  const ethBridge = new ethers.Contract(
    ethBridgeAddr,
    BridgeAbi.abi,
    ethProvider
  );
  const polBridge = new ethers.Contract(polBridgeAddr, BridgeAbi.abi, wallet);

  const bridgeRequestedTopic = ethers.id(
    "BridgeRequested(address,address,address,address,uint256,uint256,uint256,uint256)"
  );

  let lastProcessed = await ethProvider.getBlockNumber();
  console.log("Relayer started. Watching new events...");

  setInterval(async () => {
    try {
      const latestBlock = await ethProvider.getBlockNumber();
      if (latestBlock <= lastProcessed) return;

      const logs = await ethProvider.getLogs({
        fromBlock: lastProcessed + 1,
        toBlock: latestBlock,
        address: ethBridgeAddr,
        topics: [bridgeRequestedTopic],
      });

      for (const log of logs) {
        const parsed = ethBridge.interface.parseLog(log);
        let { from, to, srcToken, dstToken, srcAmount, dstAmount, nonce } =
          parsed.args;

        console.log("Detected BridgeRequested:");
        console.log({
          from,
          to,
          srcToken,
          dstToken,
          srcAmount,
          dstAmount,
          nonce,
        });

        // map token for destination chain
        const mappedDstToken = TOKEN_MAP[dstToken] || dstToken;

        try {
          const tx = await polBridge.release(
            mappedDstToken,
            to,
            dstAmount,
            nonce
          );
          console.log("Release tx sent:", tx.hash);
          await tx.wait();
          console.log("Release confirmed.");
        } catch (err) {
          console.error("Release failed:", err);
        }
      }

      lastProcessed = latestBlock;
    } catch (err) {
      console.error("Polling error:", err);
    }
  }, 10_000);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
