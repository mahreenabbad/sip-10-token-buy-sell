import {
  Cl,
  Pc,
  principalCV,
  makeContractCall,
  createStacksPrivateKey,
  makeRandomPrivKey,
  getPublicKey,
  makeContractDeploy,
  broadcastTransaction,
  contractPrincipalCV,
  uintCV,
  callReadOnlyFunction,
  PostConditionMode,
  bufferCVFromString,
  bufferCV,
  someCV,
  FungibleConditionCode,
  makeContractFungiblePostCondition,
  makeStandardSTXPostCondition,
  makeContractSTXPostCondition,
} from "@stacks/transactions";
import { STACKS_TESTNET } from "@stacks/network";
import { readFileSync } from "fs";
import { generateWallet, generateNewAccount } from "@stacks/wallet-sdk";

// async function keyGenerate() {
//   let wallet = await generateWallet({
//     secretKey:
//       "",
//     password: "",
//   });
//   wallet = generateNewAccount(wallet);
//   const account = wallet.accounts[1];
//   const privatK = account.stxPrivateKey;
//   console.log("private key", privatK);

//   console.log(wallet.accounts.length);
// }
// keyGenerate();

// //////////////////////////////////

// SMART_CONTRACT_ DEPLOY_TRANSACTION

// const txOptions = {
//   contractName: "sip-token001",
//   codeBody: readFileSync("contracts/sip-token001.clar").toString(),
//   senderKey:
//     "3a0200463dca132eaaec01",
//   network: "testnet",
//
// };

// // console.log(txOptions);
// async function deployContract() {
//   try {
//     // Create a deploy transaction
//     const transaction = await makeContractDeploy(txOptions);
//     // console.log(transaction);
//     // Broadcast the transaction
//     const broadcastResponse = await broadcastTransaction(
//       transaction,
//       txOptions.network
//     );
//     console.log("Broadcast Response:", broadcastResponse);
//   } catch (error) {
//     console.error("Error deploying contract:", error);
//   }
// }
// deployContract();

// ///////////////////////////////////////////////////////////

// //////////////////////////////////

// Smart contract function call -
// BUY FUNCTION

// const txOptions = {
//   contractAddress: "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV", // Address where the contract is deployed
//   contractName: "dex", // Contract name
//   functionName: "buy", // Function to call
//   functionArgs: [
//     //contractPrincipalCV is a utility function that creates a Clarity contract principal
//     contractPrincipalCV(
//       "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV",
//       "sip-token01"
//     ), // The SIP-10 token contract as the first argument
//     //uintCV is a utility function that creates a Clarity unsigned integer (uint)
//     uintCV(1000000), // The stx-amount in micro-STX (1 STX = 1,000,000 micro-STX)
//   ],
//   senderKey:
//     "3a0201ec01", // Sender's private key
//   validateWithAbi: true,
//   network: "testnet", // Use the testnet network
// };

// // console.log("txOptions :", txOptions);

// async function executeTransaction() {
//   try {
//     const transaction = await makeContractCall(txOptions);
//     const broadcastResponse = await broadcastTransaction(
//       transaction,
//       "testnet"
//     );
//     console.log("Transaction ID:", broadcastResponse.txid);
//   } catch (error) {
//     console.error("Error during transaction execution:", error);
//   }
// }

// executeTransaction();

// /////////////////////////////////

// SELL_FUNCTION

// const txOptions = {
//   contractAddress: "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV", // Address where the contract is deployed
//   contractName: "dex", // Contract name
//   functionName: "sell", // Function to call
//   functionArgs: [
//     //contractPrincipalCV is a utility function that creates a Clarity contract principal
//     contractPrincipalCV(
//       "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV",
//       "sip-token01"
//     ), // The SIP-10 token contract as the first argument
//     //uintCV is a utility function that creates a Clarity unsigned integer (uint)
//     uintCV(1000000), // The stx-amount in micro-STX (1 STX = 1,000,000 micro-STX)
//   ],
//   senderKey:
//     "3a020135aaaec01", // Sender's private key
//   validateWithAbi: true,
//   network: "testnet", // Use the testnet network
// };

// // console.log("txOptions :", txOptions);

// const transaction = await makeContractCall(txOptions);

// // broadcast to the network
// const response = await broadcastTransaction(transaction, "testnet");
// console.log("response : ", response);

// //////////////////////////////////////////////

// READ ONLY FUNCTION - get-buyable-tokens FUNCTION

// const options = {
//   contractAddress: "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV",
//   contractName: "dex",
//   functionName: "get-buyable-tokens",
//   functionArgs: [uintCV(1000000)], // Convert `stxAmount` into a Clarity `uint`- Example: 1 STX (1 STX = 1,000,000 micro-STX)
//   network: "testnet",
//   senderAddress: "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV",
// };

// (async () => {
//   try {
//     const result = await callReadOnlyFunction(options);
//     console.log("Raw Result:", result);

//     // Decode the result to see the returned object
//     const data = result.value.data; // Accessing the returned object
//     console.log("Decoded Result:", {
//       fee: data.fee.value, // The 2% fee
//       buyableToken: data["buyable-token"].value, //  tokens that can be bought with the specified stx-amoun
//       stxBuy: data["stx-buy"].value, // The amount of STX available for token purchase after deducting the fee
//       newTokenBalance: data["new-token-balance"].value, // The The new token balance of the contract after the tokens are purchased.
//       stxBalance: data["stx-balance"].value, // The current STX balance-The contract's current STX balance before the transaction
//       recommendStxAmount: data["recommend-stx-amount"].value, //  The recommended STX amount for the next transaction to reach the target STX amount.
//       tokenBalance: data["token-balance"].value, // Token balance- The total token balance currently held by the contract
//     });
//   } catch (error) {
//     console.error("Error calling read-only function:", error);
//   }
// })();

////////////////////////////////

// const postCondition = Pc.principal("STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV")
//   .willSendEq(1000000)
//   .ft({
//     contract: "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-token01",
//     tokenName: "mytoken",
//   });

//////////////////////////////////////////////////////////////////////
// Transfer function
// With a standard principal
const postConditionAddress = "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV";
const postConditionCode = FungibleConditionCode.GreaterEqual;
const postConditionAmount = 1000000n;

const standardSTXPostCondition = makeStandardSTXPostCondition(
  postConditionAddress,
  postConditionCode,
  postConditionAmount
);
//////////////////////////////////////////
const postCondition = Pc.principal("STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV")
  .willSendGte(1000000)
  .ft("STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-token001", "mytoken");
//////////////////////////////////////////
// With a contract principal
// const contractAddress1 = "SPBMRFRPPGCDE3F384WCJPK8PQJGZ8K9QKK7F59X";
// const contractName = "sip-token01";

// const contractSTXPostCondition = makeContractSTXPostCondition(
//   contractAddress1,
//   contractName,
//   postConditionCode,
//   postConditionAmount
// );
//////////////////////
const senderPrincipal = principalCV("STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV");
const recipientPrincipal = principalCV(
  "STBR07MFG2BRN4MANAKE77YVSCVB9QKK635XKEB2"
);
// Construct the optional memo argument
//const memo = someCV(bufferCV(Buffer.alloc(34, 0))); // Leave empty for no memo
const amount = Cl.uint(1000000);
const txOptions = {
  contractAddress: "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV",
  contractName: "sip-token001",
  functionName: "transfer",
  functionArgs: [
    amount, // `amount` as a Clarity uint
    senderPrincipal, // `sender` as a Clarity principal
    recipientPrincipal, // `recipient` as a Clarity principal
    Cl.none(), // `memo` as a Clarity optional buffer
  ],
  // postConditions: [postCondition],
  PostConditionMode: PostConditionMode.Allow,
  senderKey:
    "3a02013ca132eaaec01",
  network: "testnet",
};

// console.log("txOptions :", txOptions);

// Create and broadcast the transaction
const transaction = await makeContractCall(txOptions);

// console.log("Transaction:", transaction);
const response = await broadcastTransaction(transaction, "testnet");
console.log("Response:", response);
// console.log("Function Args:", txOptions.functionArgs);

// broadcast to the network

///////////////////////////////////
// // mint -Function
// const recipientPrincipal = principalCV(
//   "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV"
// );

// const amount = Cl.uint(10000000);
// const txOptions = {
//   contractAddress: "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV",
//   contractName: "sip-token001",
//   functionName: "mint",
//   functionArgs: [
//     amount, // `amount` as a Clarity uint
//     recipientPrincipal, // `recipient` as a Clarity principal
//   ],

//   PostConditionMode: PostConditionMode.Allow,
//   senderKey:
//     "3a020aaec01",
//   network: "testnet",
//
// };

// // console.log("txOptions :", txOptions);

// // Create and broadcast the transaction
// const transaction = await makeContractCall(txOptions);

// // console.log("Transaction:", transaction);
// const response = await broadcastTransaction(transaction, "testnet");
// console.log("Response:", response);

