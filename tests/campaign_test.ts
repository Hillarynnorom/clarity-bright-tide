import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures campaign creation works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("campaign", "create-campaign", 
        [
          types.utf8("Test Campaign"),
          types.utf8("Test Campaign Description"),
          types.uint(1000),
          types.uint(100)
        ], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, '(ok u0)');
  }
});

Clarinet.test({
  name: "Ensures donations work correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("campaign", "create-campaign",
        [
          types.utf8("Test Campaign"),
          types.utf8("Test Campaign Description"),
          types.uint(1000),
          types.uint(100)
        ],
        wallet_1.address
      ),
      Tx.contractCall("campaign", "donate",
        [types.uint(0), types.uint(500)],
        wallet_2.address  
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, '(ok true)');
  }
});

Clarinet.test({
  name: "Ensures withdraw-funds works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("campaign", "create-campaign",
        [
          types.utf8("Test Campaign"),
          types.utf8("Test Campaign Description"),
          types.uint(1000),
          types.uint(3)
        ],
        wallet_1.address
      )
    ]);
    
    chain.mineEmptyBlockUntil(5);
    
    block = chain.mineBlock([
      Tx.contractCall("campaign", "withdraw-funds",
        [types.uint(0)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
  }
});
