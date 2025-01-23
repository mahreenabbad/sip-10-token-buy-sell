import { 
  Cl,
  createStacksPrivateKey,
  cvToValue,
  signMessageHashRsv,
} from "@stacks/transactions";
import { beforeEach, describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();

const contractOwner = accounts.get("wallet_1");
const user1 = accounts.get("wallet_2");
const user2 = accounts.get("wallet_3");

describe("AMM Swap Contract", () => {
  let contract;

  // beforeEach(async () => {
  //   // Deploy the contract if not already deployed
  //   contract = simnet.getContractSource("buysell01",{
  //     sender:contractOwner
  //   })
    
  // });

  // it("should ensure the contract is deployed", () => {
  //   const contractSource = simnet.getContractSource("buysell01");
  //   expect(contractSource).toBeDefined();
  // });

  // it("should allow buying tokens with STX", async () => {
  //   const tokenTrait = "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-token";
  //   const amount = Cl.uint(1000); // Buy 1000 units
  //   const payWithStx = Cl.bool(true);

  //   const result = await simnet.callPublicFn({
  //     contract: "buysell01",
  //     method: "buy",
  //     args: [Cl.contractPrincipal(tokenTrait), amount, payWithStx],
  //     sender: user1,
  //   });

  //   expect(result.success).toBe(true);
  //   expect(result.value).toBeDefined();
  // });

  // it("should allow selling tokens for STX", async () => {
  //   const tokenTrait = "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-token";
  //   const tokensIn = Cl.uint(500); // Sell 500 units
  //   const payWithStx = Cl.bool(true);

  //   const result = await simnet.callPublicFn({
  //     contract: "buysell01",
  //     method: "sell",
  //     args: [Cl.contractPrincipal(tokenTrait), tokensIn, payWithStx],
  //     sender: user1,
  //   });

  //   expect(result.success).toBe(true);
  //   expect(result.value).toBeDefined();
  // });

  // it("should estimate buyable tokens for given STX amount", async () => {
  //   const stxAmount = Cl.uint(1000); // Amount in STX
  //   const payWithStx = Cl.bool(true);

  //   const result = await simnet.callReadOnlyFn({
  //     contract: "buysell01",
  //     method: "get-buyable-tokens",
  //     args: [stxAmount, payWithStx],
  //     sender: user1,
  //   });

  //   expect(result.success).toBe(true);
  //   expect(result.value.buyableToken).toBeDefined();
  // });

  // it("should estimate receivable STX for given token amount", async () => {
  //   const tokenAmount = Cl.uint(500); // Amount in tokens
  //   const payWithStx = Cl.bool(true);

  //   const result = await simnet.callReadOnlyFn({
  //     contract: "buysell01",
  //     method: "get-sellable-tokens",
  //     args: [tokenAmount, payWithStx],
  //     sender: user1,
  //   });

  //   expect(result.success).toBe(true);
  //   expect(result.value.receivableStx).toBeDefined();
  // });

  // it("should reject unauthorized token", async () => {
  //   const unauthorizedToken = "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.fake-token";
  //   const amount = Cl.uint(1000);

  //   const result = await simnet.callPublicFn({
  //     contract: "buysell01",
  //     method: "buy",
  //     args: [Cl.contractPrincipal(unauthorizedToken), amount, Cl.bool(true)],
  //     sender: user1,
  //   });

  //   expect(result.success).toBe(false);
  //   expect(result.error).toBe("ERR-UNAUTHORIZED-TOKEN");
  // });

  // it("should fail when insufficient STX balance in DEX for sell", async () => {
  //   const tokenTrait = "STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-token";
  //   const tokensIn = Cl.uint(1000000); // Large amount exceeding balance

  //   const result = await simnet.callPublicFn({
  //     contract: "buysell01",
  //     method: "sell",
  //     args: [Cl.contractPrincipal(tokenTrait), tokensIn, Cl.bool(true)],
  //     sender: user1,
  //   });

  //   expect(result.success).toBe(false);
  //   expect(result.error).toBe("DEX-HAS-NOT-ENOUGH-STX");
  // });
});
