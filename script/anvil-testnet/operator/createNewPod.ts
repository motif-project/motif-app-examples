import { ethers } from "ethers";
import * as dotenv from "dotenv";
const fs = require("fs");
const path = require("path");
dotenv.config();

// Check if the process.env object is empty
if (!Object.keys(process.env).length) {
  throw new Error("process.env object is empty");
}
// display the process.env object
// console.log(process.env);
// Setup env variables
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.CLIENT_PRIVATE_KEY!, provider);
const wallet_opr = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

/// TODO: Hack
let chainId = 31337;

const avsDeploymentData = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, `../bitdsm_addresses.json`),
    "utf8"
  )
);
const bitDSMPodMangerAddress = avsDeploymentData.BitcoinPodManagerProxy;
const bitDSMPodMangerABI = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, "../abis/BitcoinPodManager.json"),
    "utf8"
  )
);



const bitDSMServiceManagerAddress = avsDeploymentData.BitDSMServiceManagerProxy;
const bitDSMServiceManagerABI = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, "../abis/BitDSMServiceManager.json"),
    "utf8"
  )
);
const iface = new ethers.Interface(bitDSMPodMangerABI);
// Initialize contract objects from ABIs
const BodManager = new ethers.Contract(
  bitDSMPodMangerAddress,
  bitDSMPodMangerABI,
  wallet
);

const ServiceManager = new ethers.Contract(
  bitDSMServiceManagerAddress,
  bitDSMServiceManagerABI,
  wallet_opr
);



async function confirmBitcoinDeposit(
  podAddress: string,
  transactionId: string,
  amount: bigint
): Promise<boolean> {

  const messageHash = ethers.keccak256(
    ethers.solidityPacked(
      ['address', 'address', 'uint256', 'bytes32', 'bool'],
      [
        podAddress,
        wallet_opr.address,
        amount,
        transactionId,
        true
      ]
    )
  );
console.log("Message hash:", messageHash);
 const messageBytes = ethers.getBytes(messageHash);
 const signature = await wallet_opr.signMessage(messageBytes);
 console.log("Signature:", signature);
  try {
    const tx = await ServiceManager.confirmDeposit(podAddress, signature);
    const receipt = await tx.wait();
    console.log("Transaction confirmed: ${receipt.hash}");
    return true;
  } catch (error) {
    console.error("Transaction failed:", error);
    return false;
  }
}

async function createNewPod(): Promise<string> {
  try {
    const tx = await BodManager.createPod(
      wallet_opr.address,
      "0x965d5c75ae6c7a68761e6f9cf2657363bd97f11fc6727410adacd7f81368541b"
    );
    const receipt = await tx.wait();
    console.log("Pod Created : ", receipt);

    for (const log of receipt.logs) {
      try {
        const parsedLog = iface.parseLog(log);
        if (parsedLog?.name === "PodCreated") {
          const podAddress = parsedLog.args.pod;
          console.log("Pod Address:", podAddress);
          return podAddress;
        }
      } catch (e) {
        continue;
      }
    }
    // Move this line inside the first try block, after the for loop
    throw new Error("Pod address not found in transaction logs");
  } catch (error) {
    console.error("Error sending transaction:", error);
    throw error;
  }
}


async function verifyBitcoinDeposit(
  podAddr: string,
  txHash: string,
  amount: bigint
): Promise<boolean> {
  try {
    const tx = await BodManager.verifyBitcoinDepositRequest(
      podAddr,
      txHash,
      amount
    );
    const receipt = await tx.wait();
    console.log("++++++++++++++++++++++++++++");
    console.log("Bitcoin Deposit Verified : ", receipt);
    return true;
  } catch (error) {
    console.error("Error sending transaction:", error); // Add this line to properly handle errors
    return false;
  }
}

// Function to create a new task with a random name every 15 seconds
async function CreatePodandDeposit() {
  let podAddress = await createNewPod();
  console.log("Pod Created : ", podAddress);

  let success = await verifyBitcoinDeposit(
    podAddress,
    "0xf21abe91dc7751516e22059abe925df95fa19a63669ed8a5b31f53312c3b59af",
    BigInt(10000)
  );
  console.log("Confirm request sent");
  if (true) {
    await confirmBitcoinDeposit(
      podAddress,
      "0xf21abe91dc7751516e22059abe925df95fa19a63669ed8a5b31f53312c3b59af",
      BigInt(10000)
    );
  } else {
    console.error("confirm Bitcoin Transaction Failed");
  }
  console.log("Confirmed Deposit");
}

CreatePodandDeposit();
