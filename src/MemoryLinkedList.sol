// SPDX-License-Identifier: MIT
// "Generic", memory-only/in-memory, doubly-linked list library for solidity.
// Author: @merklejerk
pragma solidity ^0.8;

// A typed pointer to a node.
type node_ptr is uint48;
// A pointer to a node's data.
// Unless the data fits entirely in a 42 bits (NOT 48), applications must allocate their data in memory
// (by using a reference type such as a struct) and use assembly to wrap the pointer into
// a `data_ptr` type. For most cases, the assembly will be a trivial assignment.
type data_ptr is uint48;

// The top-level data structure for a generic linked list.
// Intended to be consumed with `using LibLinkedList for LL`.
struct LL {
    uint256 length;
    node_ptr head;
    node_ptr tail;
}

node_ptr constant NULL_NODE_PTR = node_ptr.wrap(0);
uint256 constant FIELD_SIZE_BITS = 42; // ~4TB addressable ("uint42")
uint256 constant NODE_SIZE_BYTES = 16;
uint256 constant UINT42_BITMASK = 0x3ffffffffff;

// Check if a node != NULL_NODE_PTR.
function isValidNode(node_ptr node) pure returns (bool) {
    return node_ptr.unwrap(node) != node_ptr.unwrap(NULL_NODE_PTR);
}

// Revert if a node == NULL_NODE_PTR.
function validateNode(node_ptr node) pure {
    require(isValidNode(node), 'LL: Null node');
}

function validateDataPtr(data_ptr data) pure {
    assembly ("memory-safe") {
        if gt(data, UINT42_BITMASK) {
            // Panic(uint256(0x21))
            mstore(0x00, hex"4e487b71")
            mstore(0x04, 0x21)
            revert(0x00, 0x24)
        }
    }
}

// Extract a node's fields.
function getNode(node_ptr node)
    pure
    returns (data_ptr data, node_ptr prev, node_ptr next)
{
    // `node` points to memory location where 3 uint42s are packed
    // into the upper half of a single 128-bit half word:
    //      +----------+--------+----------------+
    //      | bits     | type   | detail         |
    //      +----------+--------+----------------+
    //      | 214-256  | uint42 | data ptr       |
    //      | 172-214  | uint42 | prev node ptr  |
    //      | 130-172  | uint42 | next node ptr  |
    //      +----------+--------+----------------+
    // Note that the lowest 2 bits (128-130) of the half word are unused.
    assembly ("memory-safe") {
        let w := mload(node)
        // w >> 214
        data := shr(214, w)
        // (w << 42) >> 214
        prev := shr(214, shl(42, w))
        // (w << 84) >> 214
        next := shr(214, shl(84, w))
    }
}

// Set an existing node's fields.
function setNode(node_ptr node, data_ptr data, node_ptr prev, node_ptr next)
    pure returns (node_ptr)
{
    assembly ("memory-safe") {
        mstore(
            node,
            or(
                // Only replace the upper 126 bits of the word.
                shr(126, shl(126, mload(node))),
                or(
                    or(
                        shl(214, data),
                        shr(42, shl(214, prev))
                    ),
                    shr(84, shl(214, next))
                )
            )
        )
    }
    return node;
}

// Allocate a new node and set its fields.
function allocNode(data_ptr data, node_ptr prev, node_ptr next)
    pure returns (node_ptr node)
{
    assembly ("memory-safe") {
        node := mload(0x40)
        mstore(0x40, add(node, NODE_SIZE_BYTES))
    }
    setNode(node, data, prev, next);
}

library LibLinkedListNode {
    node_ptr constant internal NULL = NULL_NODE_PTR;

    // Get the next node in the list.
    // Returns `NULL_NODE_PTR` if no more.
    function next(node_ptr node)
        internal pure returns (node_ptr next_)
    {
        validateNode(node);
        (,, next_) = getNode(node);
    }

    // Get the previous node in the list.
    // Returns `NULL_NODE_PTR` if no more.
    function prev(node_ptr node)
        internal pure returns (node_ptr prev_)
    {
        validateNode(node);
        (, prev_,) = getNode(node);
    }

    // Get the data ptr held by a node.
    function data(node_ptr node)
        internal pure returns (data_ptr data_)
    {
        validateNode(node);
        (data_,,) = getNode(node);
    }

    // Check if a node is valid (!= NULL_NODE_PTR).
    function isValid(node_ptr node)
        internal pure returns (bool)
    {
        return isValidNode(node);
    }

    // Check if a node is the first in the list.
    function isHead(node_ptr node)
        internal pure returns (bool)
    {
        validateNode(node);
        return !isValid(prev(node));
    }

    // Check if a node is the last in the list.
    function isTail(node_ptr node)
        internal pure returns (bool)
    {
        validateNode(node);
        return !isValid(next(node));
    }

    // Replace the data pointer in a node.
    function set(node_ptr node, data_ptr data_)
        internal pure returns (node_ptr)
    {
        validateNode(node);
        validateDataPtr(data_);
        _set(node, data_);
        return node;
    }

    // Swap data between two nodes.
    function swap(node_ptr a, node_ptr b)
        internal pure
    {
        data_ptr dataA = data(a);
        _set(a, data(b));
        _set(b, dataA);
    }

    function eq(node_ptr nodeA, node_ptr nodeB)
        internal pure returns (bool)
    {
        return node_ptr.unwrap(nodeA) == node_ptr.unwrap(nodeB);
    }

    function _set(node_ptr node, data_ptr data_)
        private pure
    {
        validateDataPtr(data_);
        assembly ("memory-safe") {
            mstore(
                node,
                // Only replace upper 42 bits of word.
                or(
                    shr(42, shl(42, mload(node))),
                    shl(214, data_)
                )
            )
        }
    }
}


library LibLinkedList {
    using LibLinkedListNode for node_ptr;

    // Get the node at an index.
    function at(LL memory ll, uint256 idx)
        internal pure returns (node_ptr node)
    {
        unchecked {
            require(idx < ll.length, 'LL: OOB');
            if (idx < ll.length / 2) {
                node = ll.head;
                while (idx != 0) {
                    node = node.next();
                    --idx;
                }
            } else {
                node = ll.tail;
                uint256 t = ll.length - 1;
                while (idx != t) {
                    node = node.prev();
                    ++idx;
                }
            }
        }
    }

    // Empty out the list.
    function clear(LL memory ll)
        internal pure
    {
        ll.head = ll.tail = NULL_NODE_PTR;
        ll.length = 0;
    }

    // Search through the list using the predicate `isNeedle()`, returning
    // the first node on which it returns `true`. If `isNeedle()` never
    // returns `true`, returns `NULL_NODE_PTR` instead.
    function find(
        LL memory ll,
        function (node_ptr, uint256, bytes memory) view returns (bool) isNeedle,
        bytes memory callerData
    ) internal view returns (node_ptr node, uint256 idx) {
        node = ll.head;
        while (isValidNode(node)) {
            if (isNeedle(node, idx, callerData)) {
                return (node, idx);
            }
            node = node.next();
            unchecked { ++idx; }
        }
        return (node, type(uint256).max);
    }

    // Search through the list in reverse using the predicate `isNeedle()`, returning
    // the first node on which it returns `true`. If `isNeedle()` never
    // returns `true`, returns `NULL_NODE_PTR` instead.
    function rfind(
        LL memory ll,
        function (node_ptr, uint256, bytes memory) view returns (bool) isNeedle,
        bytes memory callerData
    ) internal view returns (node_ptr node, uint256 idx) {
        idx = ll.length;
        node = ll.tail;
        while (isValidNode(node)) {
            unchecked { --idx; }
            if (isNeedle(node, idx, callerData)) {
                return (node, idx);
            }
            node = node.prev();
        }
        return (node, type(uint256).max);
    }

    // Call an iterator on each node.
    // The callback will receive the node, its index, and the `callerData` provided to
    // this function.
    function each(
        LL memory ll,
        function (node_ptr, uint256, bytes memory) returns (bool) onNode,
        bytes memory callerData
    ) internal {
        uint256 idx;
        node_ptr node = ll.head;
        while (isValidNode(node)) {
            if (!onNode(node, idx, callerData)) {
                break;
            }
            node = node.next();
            unchecked { ++idx; }
        }
    }

    // Call an iterator on each node in reverse.
    // The callback will receive the node, its index, and the `callerData` provided to
    // this function.
    function reach(
        LL memory ll,
        function (node_ptr, uint256, bytes memory) returns (bool) onNode,
        bytes memory callerData
    ) internal {
        uint256 idxP1 = ll.length;
        node_ptr node = ll.tail;
        while (isValidNode(node)) {
            unchecked { --idxP1; }
            if (!onNode(node, idxP1, callerData)) {
                break;
            }
            node = node.prev();
        }
    }

    // Call an iterator on each node (static callback version).
    // The callback will receive the node, its index, and the `callerData` provided to
    // this function.
    function each_static(
        LL memory ll,
        function (node_ptr, uint256, bytes memory) view returns (bool) onNode,
        bytes memory callerData
    ) internal view {
        // Some solidity hacks to reuse non-static code path.
        function (
            LL memory,
            function (node_ptr, uint256, bytes memory) returns (bool),
            bytes memory
        ) fn_ptr = each;
        function (
            LL memory,
            function (node_ptr, uint256, bytes memory) view returns (bool),
            bytes memory
        ) view static_fn_ptr;
        assembly ("memory-safe") { static_fn_ptr := fn_ptr }
        return static_fn_ptr(ll, onNode, callerData);
    }

    // Call an iterator on each node in reverse (static callback version).
    // The callback will receive the node, its index, and the `callerData` provided to
    // this function.
    function reach_static(
        LL memory ll,
        function (node_ptr, uint256, bytes memory) view returns (bool) onNode,
        bytes memory callerData
    ) internal view {
        // Some solidity hacks to reuse non-static code path.
        function (
            LL memory,
            function (node_ptr, uint256, bytes memory) returns (bool),
            bytes memory
        ) fn_ptr = reach;
        function (
            LL memory,
            function (node_ptr, uint256, bytes memory) view returns (bool),
            bytes memory
        ) view static_fn_ptr;
        assembly ("memory-safe") { static_fn_ptr := fn_ptr }
        return static_fn_ptr(ll, onNode, callerData);
    }

    // Insert a new node at the end of the list.
    function push(LL memory ll, data_ptr data)
        internal pure
    {
        insertBefore(ll, NULL_NODE_PTR, data);
    }

    function push2(LL memory ll, data_ptr data)
        internal pure
    {
        insertBefore(ll, NULL_NODE_PTR, data);
    }

    // Insert a new node at the start of the list.
    function unshift(LL memory ll, data_ptr data)
        internal pure
    {
        return insertBefore(ll, ll.head, data);
    }

    // Remove a node from the end of the list, returning its data.
    function pop(LL memory ll)
        internal pure returns (data_ptr data)
    {
        require(isValidNode(ll.tail), 'LL: Empty');
        (data,,) = getNode(ll.tail);
        _remove(ll, ll.tail);
    }

    // Remove a node from the start of the list, returning its data.
    function shift(LL memory ll)
        internal pure returns (data_ptr data)
    {
        require(isValidNode(ll.head), 'LL: Empty');
        (data,,) = getNode(ll.head);
        _remove(ll, ll.head);
    }

    // Remove a node from the list.
    function remove(LL memory ll, node_ptr node)
        internal pure
    {
        validateNode(node);
        _remove(ll, node);
    }

    function _remove(LL memory ll, node_ptr node)
        private pure
    {
        (data_ptr data, node_ptr prev, node_ptr next) = getNode(node);
        if (isValidNode(prev)) {
            (data_ptr prevData, node_ptr prevPrev,) = getNode(prev);
            setNode(prev, prevData, prevPrev, next);
        } else {
            ll.head = next;
        }
        if (isValidNode(next)) {
            (data_ptr nextData,, node_ptr nextNext) = getNode(next);
            setNode(next, nextData, prev, nextNext);
        } else {
            ll.tail = prev;
        }
        --ll.length;
        setNode(node, data, NULL_NODE_PTR, NULL_NODE_PTR);
    }

    // Insert a node before another one in the list.
    // To insert to the end, pass `NULL_NODE_PTR` for `beforeNode`.
    function insertBefore(LL memory ll, node_ptr beforeNode, data_ptr data)
        internal pure
    {
        validateDataPtr(data);
        node_ptr prev;
        node_ptr node;
        if (isValidNode(beforeNode)) {
            data_ptr beforeData;
            node_ptr beforeNext;
            (beforeData, prev, beforeNext) = getNode(beforeNode);
            node = allocNode(data, prev, beforeNode);
            setNode(beforeNode, beforeData, node, beforeNext);
        } else {
            prev = ll.tail;
            ll.tail = node = allocNode(data, prev, NULL_NODE_PTR);
        }
        if (isValidNode(prev)) {
            (data_ptr prevData, node_ptr prevPrev,) = getNode(prev);
            setNode(prev, prevData, prevPrev, node);
        } else {
            ll.head = node;
        }
        ++ll.length;
    }
}