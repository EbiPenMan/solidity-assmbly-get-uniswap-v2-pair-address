// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract GetPair {
    address public factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public token0 = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public token1 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; 

    // DAI  : 0x6b175474e89094c44da98b954eedeac495271d0f
    // USDC : 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
    // pool : 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5

    // return bytes: 0xd257ccbe93e550a27236e8cc4971336f6cd2d53037ad567f10fbcc28df6a1eb1
    function A_S() external view returns (bytes memory) {
        return abi.encode(keccak256(abi.encodePacked(token0, token1)));
    }

    // return bytes: 0x8bb515c59c8ed89250b9316105ba225d5aebd720e87e69f2ba78fad8fab9ea7d
    function A_A() external view returns (bytes memory) {
        bytes memory result;
        assembly {
            // Load the storage slots
            let _token0 := sload(token0.slot)
            let _token1 := sload(token1.slot)

            // Clear the higher-order bits (ensure the values are properly 160 bits)
            // https://docs.soliditylang.org/en/latest/assembly.html
            // Warning
            // 
            // If you access variables of a type that spans less than 256 bits
            // (for example uint64, address, or bytes16), you cannot make any 
            // assumptions about bits not part of the encoding of the type.
            // Especially, do not assume them to be zero. To be safe,
            // always clear the data properly before you use it in a context
            // where this is important: 
            // uint32 x = f(); assembly { x := and(x, 0xffffffff) /* now use x */ }
            // To clean signed types, you can use the signextend opcode:
            // assembly { signextend(<num_bytes_of_x_minus_one>, x) }
            _token0 := and(_token0, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) // 20 bytes
            _token1 := and(_token1, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) // 20 bytes

            // Load the free memory pointer
            let ptr := mload(0x40)

            // Store token0 at ptr
            mstore(ptr, shl(96, _token0)) // Shift left to align with 20 bytes
            // Store token1 at ptr + 0x14 (20 decimal)
            mstore(add(ptr, 0x14), shl(96, _token1)) // Shift left to align with 20 bytes

            // Calculate the hash 
            // length of two 20 bytes (0x14 hex) = 40 (0x28 hex)
            let hash := keccak256(ptr, 0x28)

            // Allocate memory for the result
            // We need 32 bytes for the length prefix and 32 bytes for the hash
            let resultPtr := add(ptr, 0x40)
            mstore(0x40, add(resultPtr, 0x40))

            // Store the length of the bytes array (32 bytes)
            mstore(resultPtr, 0x20)
            // Store the hash after the length prefix
            mstore(add(resultPtr, 0x20), hash)

            // Set the result to point to the allocated memory
            result := resultPtr
        }
        return result;
    }


    // return: 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5
    function getPairAddress() external view returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            )))));
    }

    function get2PairAddressAsm() external view returns (address pair) {
        assembly {

            // Load the storage slots
            let _factory := sload(factory.slot)
            let _token0 := sload(token0.slot)
            let _token1 := sload(token1.slot)

            // Clear the higher-order bits (ensure the values are properly 160 bits)
            // https://docs.soliditylang.org/en/latest/assembly.html
            // Warning
            // 
            // If you access variables of a type that spans less than 256 bits
            // (for example uint64, address, or bytes16), you cannot make any 
            // assumptions about bits not part of the encoding of the type.
            // Especially, do not assume them to be zero. To be safe,
            // always clear the data properly before you use it in a context
            // where this is important: 
            // uint32 x = f(); assembly { x := and(x, 0xffffffff) /* now use x */ }
            // To clean signed types, you can use the signextend opcode:
            // assembly { signextend(<num_bytes_of_x_minus_one>, x) }
            _factory := and(_factory, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) // 20 bytes
            _token0 := and(_token0, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) // 20 bytes
            _token1 := and(_token1, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) // 20 bytes

            let ptr := mload(0x40)

            // Store the constant prefix (0xff) = 1 byte
            mstore8(ptr, 0xff)

            // address type size = 160 bits
            // Store the factory address after the prefix [256 bits (32 bytes) - 160 bits (20 bytes)] = 96 (0x60)
            mstore(add(ptr, 0x01), shl(0x60, _factory))

            // 20 + 1 = 21 (0x15) 
            mstore(add(ptr, 0x15), shl(96, _token0)) // Shift left to align with 20 bytes

            // 21 + 20 = 41 (0x29) 
            mstore(add(ptr, 0x29), shl(96, _token1)) // Shift left to align with 20 bytes

            // Compute the keccak256 hash of the token addresses 20 + 1 = 21 (0x15) | 20 + 20 = 40 (0x28)
            let tokenHash := keccak256(add(ptr, 0x15), 0x28)
            
            // Store the token hash after the factory address 32 bytes
            mstore(add(ptr, 0x15), tokenHash)

            // Store the init code hash after the token hash 21 + 32 = 53 (0x35)
            mstore(add(ptr, 0x35), 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // 32 bytes

            // Compute the final keccak256 hash 53 + 32 = 85 (0x55)
            let finalHash := keccak256(ptr, 0x55)

            // Compute the pair address by taking the last 20 bytes of the final hash
            pair := and(finalHash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }
}