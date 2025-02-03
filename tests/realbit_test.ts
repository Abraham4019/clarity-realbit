import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can register new property",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const agent = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("realbit-property", "register-property", [
        types.utf8("Luxury Villa"),
        types.utf8("123 Ocean Drive"),
        types.uint(1000000),
        types.principal(agent.address)
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, "(ok u1)");
  },
});

Clarinet.test({
  name: "Can create and transfer shares",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    // Test implementation
  },
});
