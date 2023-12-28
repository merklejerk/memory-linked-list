# Memory Linked List
A space-efficient, "generic", memory-only, doubly linked list implementation written in solidity. Use this if you want cheap, incremental resizing of a list, O(1) insertions/deletions, and don't mind O(n/2) lookups.

⚠️ This project hasn't been audited; use at your own risk! ⚠️

### Key Features
* The biggest difference between this from other solidity linked list implementations is that it does not use storage at all.
* By using memory pointers as the data stored in each node, any reference type (structs, arrays, etc) can be indexed by the linked list by defining a simple casting function (see [example](#example)).
* It's also quite space-efficient, with each new node only expanding memory by 16 bytes (half a word).

## Installation
To use in your foundry project, install this repo as a dependency:

```bash
$> forge install merklejerk/memory-linked-list
```

## Example

```solidity
pragma solidity ^0.8;
import { LibLinkedList, LibLinkedListNode, data_ptr, node_ptr, LL }
    from 'memory-linked-list/src/MemoryLinkedList.sol';

contract ToyExample {
    using LibLinkedListNode for node_ptr;
    using LibLinkedList for LL;

    event LogData(Data);
    event LogUint(uint256);

    // Whatever data you need to store per node.
    // Must be a reference type, so either a struct or array.
    struct Data {
        string msg;
        bytes32 msgHash;
    }

    function doStuff(string[] memory msgs) external {
        // Populate a linked list.
        LL memory ll;
        for (uint256 i; i < msgs.length; ++i) {
            Data memory data = Data(msgs[i], keccak256(msgs[i]));
            ll.push(_toDataPtr(data)); // or ll.unshift() or ll.insertBefore()
        }
        // Emit the list length.
        emit LogUint(ll.length);
        // Emit the third item.
        emit LogData(_fromDataPtr(ll.at(2).data()));
        // Insert a new item between the first and second items.
        ll.insertBefore(ll.at(1), _toDataPtr(Data('test', hex"1234")));
        // Remove the second item (which will be what we just added).
        ll.remove(ll.at(1));
        // Remove the first item and emit it.
        emit Logdata(_fromDataPtr(ll.shift().data()));
        // Walk through all entries and emit each one.
        {
            node_ptr node = ll.head;
            while (node.isValid()) {
                emit LogData(_fromDataPtr(node.data()));
                node = node.next(); // Or node.prev() to go in reverse.
            }
        }
        // Or do the same thing via each() + callback.
        ll.each(_emitEachCallback, ''); // Or ll.reach() to walk backwards.
        // Search for the first item that matches a callback predicate and replace
        // the data it points to.
        {
            // Or use ll.rfind() to search backwards.
            (node_ptr node, uint256 idx) =
                ll.find(_matchesHash, abi.encode(bytes32(0x1234)));
            if (node.isValid()) {
                node.set(_toDataPtr(Data('hello', bytes32(0x5555))));
            }
        }
        // Clear the list.
        ll.clear();
    }

    function _emitEachCallback(node_ptr node, uint256 idx, bytes memory callerData)
        private returns (bool)
    {
        emit LogData(_fromDataPtr(node.data()));
        return true; // Return false to stop early.
    }

    function _matchesHash(node_ptr node, uint256 idx, bytes memory callerData)
        private pure returns (bool)
    {
        bytes32 needle = abi.decode(callerData, (bytes32));
        return _fromDataPtr(node.data()).msgHash == needle;
    }

    /*-- Every project will need to define these two casting functions themselves. --*/

    function _fromDataPtr(data_ptr ptr) private pure returns (Data memory data) {
        assembly ("memory-safe") { data := ptr }
    }

    function _toDataPtr(Data memory data) private pure returns (data_ptr ptr) {
        assembly ("memory-safe") { ptr := data }
    }
}
```

You can find many more examples in the [tests](./test/MemoryLinkedList.t.sol)!

## Benchmarks

[Benchmarks](./test/MemoryLinkedListBench.t.sol) are run with `via_ir=true`.

| Feature                           | Cost      |
|-----------------------------------|-----------|
| Memory expansion per item         | 16 bytes  |
| `push()`/`unshift()`              | ~500 gas  |
| `pop()`/`shift()`                 | ~600 gas  |
| `at(i)` per `i` (max `N / 2`)     | ~150 gas  |

## Development

This is a [foundry](https://getfoundry.sh/) projects, so it's the usual:

```bash
# Clone the repo
$> git clone git@github.com:merklejerk/memory-linked-list && cd memory-linked-list
# Install deps.
$> forge install
# Build
$> forge build
# Run tests
$> forge test
```