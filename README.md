I'm trying to rewrite such code in assembly, but I get a completely different address uniswap v2 pair than in solidity. How can I write similar code in yul?

```solidity
address pair = address(uint160(uint(keccak256(abi.encodePacked(
  hex'ff',
  factory,
  keccak256(abi.encodePacked(token0, token1)),
  hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
)))));
```
---


1. Address Type and Size:
   - In Solidity, an address type is 20 bytes (160 bits), whereas most other data types in Solidity and Ethereum's EVM use 32 bytes (256 bits). This size difference means we need to handle addresses carefully when working directly with memory in inline assembly.

2. Using `abi.encodePacked` in Solidity:
   - The abi.encodePacked function in Solidity packs the data tightly without padding. When encoding address types, it only uses 20 bytes per address. This behavior must be mirrored in our assembly code.

3. Clearing Higher-Order Bits:
   - When working with data types that span less than 256 bits, such as address, the higher-order bits (the remaining bits that make up 32 bytes) are not guaranteed to be zero. Therefore, we must explicitly clear these bits to avoid incorrect results.

4. Shift Left Operation:
   - To store the 20-byte addresses correctly in a 32-byte memory slot, we use a left shift operation (shl(96, _token0)). This aligns the 20-byte address to the left of the 32-byte memory slot, filling the remaining bits with zeros.


I tried to write the codes with comments. I hope this code solves your problem.
