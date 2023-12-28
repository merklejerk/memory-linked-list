// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import { Test, console2 } from "forge-std/Test.sol";
import {
    LL,
    LibLinkedList,
    LibLinkedListNode,
    node_ptr,
    data_ptr
} from "../src/MemoryLinkedList.sol";

contract MemoryLinkedListTest is Test {
    using LibLinkedListNode for node_ptr;
    using LibLinkedList for LL;

    struct Data {
        uint256 x;
    }

    function test_dataPtr() external {
        Data memory data = Data(100);
        _assertSameDataPtr(_toDataPtr(data), _toDataPtr(data));
        _assertSameDataInstance(_fromDataPtr(_toDataPtr(data)), data);
        assertEq(_fromDataPtr(_toDataPtr(data)).x, data.x);
    }

    function test_emptyList() external {
        LL memory ll;
        _assertEmptyListLinks(ll);
    }

    function test_emptyList_at_indexOutOfBounds() external {
        LL memory ll;
        vm.expectRevert('LL: OOB');
        ll.at(0);
    }

    function test_emptyList_pop() external {
        LL memory ll;
        vm.expectRevert('LL: Empty');
        ll.pop();
    }

    function test_emptyList_shift() external {
        LL memory ll;
        vm.expectRevert('LL: Empty');
        ll.shift();
    }

    function test_emptyList_push() external {
        LL memory ll;
        Data memory data = Data(100);
        ll.push(_toDataPtr(data));
        assertEq(ll.length, 1);
        _assertSameNodePtr(ll.head, ll.tail);
        _assertSameDataPtr(ll.head.data(), _toDataPtr(data));
        _assertSameDataInstance(_fromDataPtr(ll.head.data()), data);
    }

    function test_emptyList_unshift() external {
        LL memory ll;
        Data memory data = Data(100);
        ll.unshift(_toDataPtr(data));
        _assertSameNodePtr(ll.head, ll.tail);
        _assertSameDataPtr(ll.head.data(), _toDataPtr(data));
        _assertSameDataInstance(_fromDataPtr(ll.head.data()), data);
    }

    function test_push_many() external {
        LL memory ll;
        Data[] memory datum = new Data[](128);
        for (uint256 i; i < 128; ++i) {
            Data memory data = Data(_makeUint(i));
            datum[i] = data;
            ll.push(_toDataPtr(data));
            _assertSameDataPtr(ll.tail.data(), _toDataPtr(data));
        }
        assertEq(ll.length, datum.length);
    }

    function test_node_methods() external {
        uint256[3] memory vals = [uint256(1337), uint256(2337), uint256(3337)];
        LL memory ll = _create3List(vals);
        assertTrue(ll.head.isValid());
        assertTrue(ll.tail.isValid());
        assertFalse(ll.head.prev().isValid());
        assertFalse(ll.tail.next().isValid());
        assertTrue(ll.head.isHead());
        assertFalse(ll.head.isTail());
        assertTrue(ll.tail.isTail());
        assertFalse(ll.tail.isHead());
        vm.expectRevert('LL: Null node');
        ll.tail.next().isTail();
        vm.expectRevert('LL: Null node');
        ll.tail.prev().isHead();
        _assertSameNodePtr(ll.head.next(), ll.tail.prev());
        _assertSameNodePtr(ll.head, ll.tail.prev().prev());
        _assertSameNodePtr(ll.head.next().next(), ll.tail);
        _assertSameNodePtr(ll.head, ll.head.next().prev());
        _assertSameNodePtr(ll.tail, ll.tail.prev().next());
        assertEq(_fromDataPtr(ll.head.data()).x, vals[0]);
        assertEq(_fromDataPtr(ll.tail.prev().data()).x, vals[1]);
        assertEq(_fromDataPtr(ll.tail.data()).x, vals[2]);
        assertTrue(ll.head.eq(ll.head));
        assertTrue(ll.head.eq(ll.tail.prev().prev()));
        assertTrue(ll.head.next().next().eq(ll.tail));
        assertTrue(ll.head.next().eq(ll.tail.prev()));
    }

    function test_node_set() external {
        uint256[3] memory vals = [uint256(1337), uint256(2337), uint256(3337)];
        LL memory ll = _create3List(vals);
        // Replace the data ptr.
        ll.head.next().set(_toDataPtr(Data(888)));
        _assert3ListLinks(ll, [uint256(1337), uint256(888), uint256(3337)]);
        // Update the data at the ptr directly.
        _fromDataPtr(ll.tail.data()).x = 5;
        _assert3ListLinks(ll, [uint256(1337), uint256(888), uint256(5)]);
    }

    function test_node_swap() external {
        uint256[3] memory vals = [uint256(1337), uint256(2337), uint256(3337)];
        LL memory ll = _create3List(vals);
        ll.head.swap(ll.head); // noop
        _assert3ListLinks(ll, [uint256(1337), uint256(2337), uint256(3337)]);
        ll.head.next().swap(ll.head);
        _assert3ListLinks(ll, [uint256(2337), uint256(1337), uint256(3337)]);
        vm.expectRevert('LL: Null node');
        ll.head.next().swap(ll.head.prev());
        vm.expectRevert('LL: Null node');
        ll.head.prev().swap(ll.head);
    }

    function test_emptyList_links() external {
        LL memory ll;
        _assertEmptyListLinks(ll);
        vm.expectRevert('LL: Null node');
        ll.head.next();
        vm.expectRevert('LL: Null node');
        ll.head.prev();
        vm.expectRevert('LL: Null node');
        ll.tail.next();
        vm.expectRevert('LL: Null node');
        ll.tail.prev();
    }

    function test_2List_links() external {
        uint256[2] memory vals = [uint256(1337), uint256(2337)];
        LL memory ll = _create2List(vals);
        _assert2ListLinks(ll, vals);
    }

    function test_3List_links() external {
        uint256[3] memory vals = [uint256(1337), uint256(2337), uint256(3337)];
        LL memory ll = _create3List(vals);
        _assert3ListLinks(ll, vals);
    }

    function test_3ListUnshift_links() external {
        uint256[3] memory vals = [uint256(1337), uint256(2337), uint256(3337)];
        LL memory ll = _create3ListUnshift(vals);
        _assert3ListLinks(ll, vals);
    }

    function test_4List_links() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4List(vals);
        _assert4ListLinks(ll, vals);
    }

    function test_4ListUnshift_links() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4ListUnshift(vals);
        _assert4ListLinks(ll, vals);
    }

    function test_4List_pushUnshift_links1() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll;
        ll.push(_toDataPtr(Data(vals[2])));
        ll.unshift(_toDataPtr(Data(vals[1])));
        ll.unshift(_toDataPtr(Data(vals[0])));
        ll.push(_toDataPtr(Data(vals[3])));
        _assert4ListLinks(ll, vals);
    }

    function test_4List_pushUnshift_links2() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll;
        ll.push(_toDataPtr(Data(vals[2])));
        ll.unshift(_toDataPtr(Data(vals[1])));
        ll.push(_toDataPtr(Data(vals[3])));
        ll.unshift(_toDataPtr(Data(vals[0])));
        _assert4ListLinks(ll, vals);
    }
    
    function test_4List_pushUnshift_links3() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll;
        ll.unshift(_toDataPtr(Data(vals[1])));
        ll.push(_toDataPtr(Data(vals[2])));
        ll.unshift(_toDataPtr(Data(vals[0])));
        ll.push(_toDataPtr(Data(vals[3])));
        _assert4ListLinks(ll, vals);
    }
    function test_4List_at() external {
        LL memory ll = _create4List([uint256(1337), uint256(2337), uint256(3337), uint256(4337)]);
        assertEq(ll.length, 4);
        assertEq(_fromDataPtr(ll.at(0).data()).x, 1337);
        assertEq(_fromDataPtr(ll.at(1).data()).x, 2337);
        assertEq(_fromDataPtr(ll.at(2).data()).x, 3337);
        assertEq(_fromDataPtr(ll.at(3).data()).x, 4337);
        vm.expectRevert('LL: OOB');
        ll.at(4);
    }

    function test_3List_at() external {
        LL memory ll = _create3List([uint256(1337), uint256(2337), uint256(3337)]);
        assertEq(ll.length, 3);
        assertEq(_fromDataPtr(ll.at(0).data()).x, 1337);
        assertEq(_fromDataPtr(ll.at(1).data()).x, 2337);
        assertEq(_fromDataPtr(ll.at(2).data()).x, 3337);
        vm.expectRevert('LL: OOB');
        ll.at(3);
    }

    function test_2List_at() external {
        LL memory ll = _create2List([uint256(1337), uint256(2337)]);
        assertEq(ll.length, 2);
        assertEq(_fromDataPtr(ll.at(0).data()).x, 1337);
        assertEq(_fromDataPtr(ll.at(1).data()).x, 2337);
        vm.expectRevert('LL: OOB');
        ll.at(2);
    }

    function test_4List_clear() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4List(vals);
        ll.clear();
        _assertEmptyListLinks(ll);
    }

    function test_4List_popToEmpty() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4List(vals);
        _assert4ListLinks(ll, vals);
        assertEq(_fromDataPtr(ll.pop()).x, 4337);
        _assert3ListLinks(ll, [uint256(1337), uint256(2337), uint256(3337)]);
        assertEq(_fromDataPtr(ll.pop()).x, 3337);
        _assert2ListLinks(ll, [uint256(1337), uint256(2337)]);
        assertEq(_fromDataPtr(ll.pop()).x, 2337);
        _assert1ListLinks(ll, [uint256(1337)]);
        assertEq(_fromDataPtr(ll.pop()).x, 1337);
        _assertEmptyListLinks(ll);
    }

    function test_4List_shiftToEmpty() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4List(vals);
        _assert4ListLinks(ll, vals);
        assertEq(_fromDataPtr(ll.shift()).x, 1337);
        _assert3ListLinks(ll, [uint256(2337), uint256(3337), uint256(4337)]);
        assertEq(_fromDataPtr(ll.shift()).x, 2337);
        _assert2ListLinks(ll, [uint256(3337), uint256(4337)]);
        assertEq(_fromDataPtr(ll.shift()).x, 3337);
        _assert1ListLinks(ll, [uint256(4337)]);
        assertEq(_fromDataPtr(ll.shift()).x, 4337);
        _assertEmptyListLinks(ll);
    }

    function test_4List_popShiftToEmpty() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4List(vals);
        _assert4ListLinks(ll, vals);
        assertEq(_fromDataPtr(ll.pop()).x, 4337);
        _assert3ListLinks(ll, [uint256(1337), uint256(2337), uint256(3337)]);
        assertEq(_fromDataPtr(ll.shift()).x, 1337);
        _assert2ListLinks(ll, [uint256(2337), uint256(3337)]);
        assertEq(_fromDataPtr(ll.shift()).x, 2337);
        _assert1ListLinks(ll, [uint256(3337)]);
        assertEq(_fromDataPtr(ll.pop()).x, 3337);
        _assertEmptyListLinks(ll);
    }

    function test_3List_popUnshiftPushShift() external {
        LL memory ll = _create3List([uint256(1337), uint256(2337), uint256(3337)]);
        _assert3ListLinks(ll, [uint256(1337), uint256(2337), uint256(3337)]);
        assertEq(_fromDataPtr(ll.pop()).x, 3337);
        _assert2ListLinks(ll, [uint256(1337), uint256(2337)]);
        ll.unshift(_toDataPtr(Data(111)));
        _assert3ListLinks(ll, [uint256(111), uint256(1337), uint256(2337)]);
        ll.push(_toDataPtr(Data(888)));
        _assert4ListLinks(ll, [uint256(111), uint256(1337), uint256(2337), uint256(888)]);
        assertEq(_fromDataPtr(ll.shift()).x, 111);
        _assert3ListLinks(ll, [uint256(1337), uint256(2337), uint256(888)]);
    }
   
    function test_2List_insertBefore() external {
        LL memory ll = _create2List([uint256(1337), uint256(2337)]);
        ll.insertBefore(ll.head.next(), _toDataPtr(Data(555)));
        ll.insertBefore(LibLinkedListNode.NULL, _toDataPtr(Data(888)));
        _assert4ListLinks(ll, [uint256(1337), uint256(555), uint256(2337), uint256(888)]);
        ll.shift();
        ll.insertBefore(ll.head, _toDataPtr(Data(111)));
        _assert4ListLinks(ll, [uint256(111), uint256(555), uint256(2337), uint256(888)]);
    }

    function test_empty_insertBefore() external {
        LL memory ll;
        ll.insertBefore(ll.head, _toDataPtr(Data(555)));
        _assert1ListLinks(ll, [uint256(555)]);
        ll.clear();
        _assertEmptyListLinks(ll);
        ll.insertBefore(LibLinkedListNode.NULL, _toDataPtr(Data(888)));
        _assert1ListLinks(ll, [uint256(888)]);
    }

    function test_empty_remove() external {
        LL memory ll;
        vm.expectRevert('LL: Null node');
        ll.remove(ll.head);
        vm.expectRevert('LL: Null node');
        ll.remove(ll.tail);
    }

    function test_2List_remove() external {
        LL memory ll = _create2List([uint256(1337), uint256(2337)]);
        ll.remove(ll.head);
        _assert1ListLinks(ll, [uint256(2337)]);
        ll.unshift(_toDataPtr(Data(uint256(1337))));
        node_ptr tail = ll.tail;
        ll.remove(tail);
        assertTrue(tail.isValid());
        assertFalse(tail.prev().isValid());
        assertFalse(tail.next().isValid());
        _assert1ListLinks(ll, [uint256(1337)]);
        ll.push(_toDataPtr(Data(uint256(2337))));
        vm.expectRevert('LL: Null node');
        ll.remove(LibLinkedListNode.NULL);
        _assertCleanMemory(ll);
    }

    function testFuzz_find(uint256 n) external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        uint256 needleIdx = n % vals.length;
        uint256 needleValue = vals[needleIdx];
        LL memory ll = _create4List(vals);
        (node_ptr node, uint256 idx) = ll.find(_isNeedleCallback, abi.encode(needleIdx, needleValue));
        assertEq(idx, needleIdx);
        assertEq(_fromDataPtr(node.data()).x, needleValue);
    }

    function test_empty_find() external {
        LL memory ll;
        (node_ptr node, uint256 idx) = ll.find(_isNeedleCallback, abi.encode(0, 1337));
        assertEq(idx, type(uint256).max);
        assertFalse(node.isValid());
    }

    function test_find_notFound() external {
        LL memory ll = _create4List([uint256(1337), uint256(2337), uint256(3337), uint256(4337)]);
        (node_ptr node, uint256 idx) = ll.find(_isNeedleCallback, abi.encode(10, 3337));
        assertEq(idx, type(uint256).max);
        assertFalse(node.isValid());
    }

    function test_rfind(uint256 n) external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        uint256 needleIdx = n % vals.length;
        uint256 needleValue = vals[needleIdx];
        LL memory ll = _create4List(vals);
        (node_ptr node, uint256 idx) = ll.rfind(_isNeedleCallback, abi.encode(needleIdx, needleValue));
        assertEq(idx, needleIdx);
        assertEq(_fromDataPtr(node.data()).x, needleValue);
    }

    function test_empty_rfind() external {
        LL memory ll;
        (node_ptr node, uint256 idx) = ll.rfind(_isNeedleCallback, abi.encode(0, 1337));
        assertEq(idx, type(uint256).max);
        assertFalse(node.isValid());
    }

    function test_rfind_notFound() external {
        LL memory ll = _create4List([uint256(1337), uint256(2337), uint256(3337), uint256(4337)]);
        (node_ptr node, uint256 idx) = ll.rfind(_isNeedleCallback, abi.encode(10, 3337));
        assertEq(idx, type(uint256).max);
        assertFalse(node.isValid());
    }

    function test_each_static_mapToArray() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4List(vals);
        uint256[] memory arr = new uint256[](vals.length);
        {
            bytes32 arrPtr;
            assembly ("memory-safe") { arrPtr := arr }
            ll.each_static(_toArrayCallback, abi.encode(arrPtr));
        }
        for (uint256 i; i < 4; ++i) {
            assertEq(arr[i], vals[i]);
        }
    }

    function test_reach_static_mapToArray() external {
        uint256[4] memory vals = [uint256(1337), uint256(2337), uint256(3337), uint256(4337)];
        LL memory ll = _create4List(vals);
        uint256[] memory arr = new uint256[](vals.length);
        {
            bytes32 arrPtr;
            assembly ("memory-safe") { arrPtr := arr }
            ll.reach_static(_toArrayCallback, abi.encode(arrPtr));
        }
        for (uint256 i; i < 4; ++i) {
            assertEq(arr[i], vals[i]);
        }
    }

    function test_empty_each_static_mapToArray() external view {
        LL memory ll;
        uint256[] memory arr = new uint256[](0);
        {
            bytes32 arrPtr;
            assembly ("memory-safe") { arrPtr := arr }
            ll.each_static(_toArrayCallback, abi.encode(arrPtr));
        }
    }

    function test_empty_reach_static_mapToArray() external view {
        LL memory ll;
        uint256[] memory arr = new uint256[](0);
        {
            bytes32 arrPtr;
            assembly ("memory-safe") { arrPtr := arr }
            ll.reach_static(_toArrayCallback, abi.encode(arrPtr));
        }
    }

    function testFuzz_bigList_canWalkForwards(uint8 n) external {
        LL memory ll;
        for (uint256 i; i < n; ++i) {
            ll.push(_toDataPtr(Data(i)));
        }
        node_ptr node = ll.head;
        uint256 idx;
        while (node.isValid()) {
            assertEq(_fromDataPtr(node.data()).x, idx);
            if (idx == n - 1) {
                _assertSameNodePtr(node, ll.tail);
            }
            node = node.next();
            ++idx;
        }
    }

    function testFuzz_bigList_canWalkBackwards(uint8 n) external {
        LL memory ll;
        for (uint256 i; i < n; ++i) {
            ll.push(_toDataPtr(Data(i)));
        }
        node_ptr node = ll.tail;
        uint256 idx;
        while (node.isValid()) {
            assertEq(_fromDataPtr(node.data()).x, n - idx - 1);
            if (idx == n - 1) {
                _assertSameNodePtr(node, ll.head);
            }
            node = node.prev();
            ++idx;
        }
    }

    function testFuzz_bigList_canAt(uint8 n) external {
        LL memory ll;
        for (uint256 i; i < n; ++i) {
            ll.push(_toDataPtr(Data(i)));
        }
        for (uint256 i; i < n; ++i) {
            node_ptr node = ll.at(i);
            assertEq(_fromDataPtr(node.data()).x, i);
            if (i == n - 1) {
                _assertSameNodePtr(node, ll.tail);
            }
        }
    }

    function _toArrayCallback(node_ptr node, uint256 idx, bytes memory callerData)
        private pure returns (bool)
    {
        bytes32 arrPtr = abi.decode(callerData, (bytes32));
        uint256[] memory arr;
        assembly ("memory-safe") { arr := arrPtr }
        arr[idx] = _fromDataPtr(node.data()).x;
        console2.log('idx:', idx, ', value:', arr[idx]);
        return true;
    }

    function _isNeedleCallback(node_ptr node, uint256 idx, bytes memory callerData)
        private pure returns (bool)
    {
        (uint256 needleIdx, uint256 needle) = abi.decode(callerData, (uint256, uint256));
        return idx == needleIdx && _fromDataPtr(node.data()).x == needle;
    }

    function _assertEmptyListLinks(LL memory ll) private {
        assertEq(ll.length, 0);
        assertFalse(ll.head.isValid());
        _assertSameNodePtr(ll.head, ll.tail);
    }

    function _assert1ListLinks(LL memory ll, uint256[1] memory vals) private {
        assertEq(ll.length, 1);
        assertFalse(ll.head.prev().isValid());
        assertFalse(ll.tail.next().isValid());
        assertFalse(ll.head.next().isValid());
        assertFalse(ll.tail.prev().isValid());
        assertEq(_fromDataPtr(ll.head.data()).x, vals[0]);
        _assertSameNodePtr(ll.head, ll.tail);
        _assertCleanMemory(ll);
    }

    function _assert2ListLinks(LL memory ll, uint256[2] memory vals) private {
        assertEq(ll.length, 2);
        assertFalse(ll.head.prev().isValid());
        assertFalse(ll.tail.next().isValid());
        assertTrue(ll.head.next().isValid());
        assertTrue(ll.tail.prev().isValid());
        assertEq(_fromDataPtr(ll.head.data()).x, vals[0]);
        assertEq(_fromDataPtr(ll.tail.data()).x, vals[1]);
        _assertSameNodePtr(ll.head.next(), ll.tail);
        _assertSameNodePtr(ll.tail.prev(), ll.head);
        _assertCleanMemory(ll);
    }

    function _assert3ListLinks(LL memory ll, uint256[3] memory vals) private {
        assertEq(ll.length, 3);
        assertFalse(ll.head.prev().isValid());
        assertFalse(ll.tail.next().isValid());
        assertTrue(ll.head.next().isValid());
        assertTrue(ll.tail.prev().isValid());
        assertEq(_fromDataPtr(ll.head.data()).x, vals[0]);
        assertEq(_fromDataPtr(ll.head.next().data()).x, vals[1]);
        assertEq(_fromDataPtr(ll.tail.data()).x, vals[2]);
        assertEq(_fromDataPtr(ll.tail.prev().data()).x, vals[1]);
        _assertSameNodePtr(ll.head.next(), ll.tail.prev());
        _assertCleanMemory(ll);
    }

    function _assert4ListLinks(LL memory ll, uint256[4] memory vals) private {
        assertEq(ll.length, 4);
        assertFalse(ll.head.prev().isValid());
        assertFalse(ll.tail.next().isValid());
        assertTrue(ll.head.next().isValid());
        assertTrue(ll.tail.prev().isValid());
        assertEq(_fromDataPtr(ll.head.data()).x, vals[0]);
        assertEq(_fromDataPtr(ll.head.next().data()).x, vals[1]);
        assertEq(_fromDataPtr(ll.tail.data()).x, vals[3]);
        assertEq(_fromDataPtr(ll.tail.prev().data()).x, vals[2]);
        _assertSameNodePtr(ll.head.next().next(), ll.tail.prev());
        _assertSameNodePtr(ll.tail.prev().prev(), ll.head.next());
        _assertCleanMemory(ll);
    }

    function _create4List(uint256[4] memory xs) private pure returns (LL memory ll) {
        for (uint256 i; i < xs.length; ++i) {
            ll.push(_toDataPtr(Data(xs[i])));
        }
    }

    function _create4ListUnshift(uint256[4] memory xs) private pure returns (LL memory ll) {
        for (uint256 i; i < xs.length; ++i) {
            ll.unshift(_toDataPtr(Data(xs[xs.length - i - 1])));
        }
    }

    function _create3List(uint256[3] memory xs) private pure returns (LL memory ll) {
        for (uint256 i; i < xs.length; ++i) {
            ll.push(_toDataPtr(Data(xs[i])));
        }
    }

    function _create3ListUnshift(uint256[3] memory xs) private pure returns (LL memory ll) {
        for (uint256 i; i < xs.length; ++i) {
            ll.unshift(_toDataPtr(Data(xs[xs.length - i - 1])));
        }
    }

    function _create2List(uint256[2] memory xs) private pure returns (LL memory ll) {
        for (uint256 i; i < xs.length; ++i) {
            ll.push(_toDataPtr(Data(xs[i])));
        }
    }

    function _toDataPtr(Data memory d) private pure returns (data_ptr ptr) {
        assembly ("memory-safe") { ptr := d }
    }

    function _fromDataPtr(data_ptr ptr) private pure returns (Data memory d) {
        assembly ("memory-safe") { d := ptr }
    }

    function _assertSameNodePtr(node_ptr a, node_ptr b) private {
        assertEq(node_ptr.unwrap(a), node_ptr.unwrap(b));
    }

    function _assertSameDataPtr(data_ptr a, data_ptr b) private {
        assertEq(data_ptr.unwrap(a), data_ptr.unwrap(b));
    }

    function _makeUint(uint256 seed) private pure returns (uint256 r) {
        assembly ("memory-safe") {
            mstore(0x00, seed)
            r := keccak256(0x00, 0x20)
        }
    }
   
    function _assertCleanMemory(LL memory ll) private {
        node_ptr node = ll.head;
        while (node.isValid()) {
            bytes16 hw;
            assembly ("memory-safe") { hw := shl(128, shr(128, mload(node))) }
            // Ensure unused bits are 0 (lowest 2 bits).
            assertEq(hw & bytes16(uint128(3)), 0x0, 'unused bits in node half word');
            node = node.next();
        }
        // Assert that the word at the free mem pointer is untouched.
        bytes32 w;
        assembly ("memory-safe") {
            w := mload(mload(0x40))
        }
        assertEq(w, 0x0, 'nonzero data in free memory!');
    }

    function _assertSameDataInstance(Data memory a, Data memory b) private {
        bytes32 locA;
        bytes32 locB;
        assembly ("memory-safe") {
            locA := a
            locB := b
        }
        assertEq(locA, locB);
    }
}
