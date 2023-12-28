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

contract MemoryLinkedListBenchTest is Test {
    using LibLinkedListNode for node_ptr;
    using LibLinkedList for LL;
    
    data_ptr constant DUMMY_DATA_PTR = data_ptr.wrap(123);
    uint256 constant NUM_SAMPLES = 384;
    uint256 _gasIdx;

    modifier gasTest() {
        vm.pauseGasMetering();
        _;
        vm.resumeGasMetering();
    }

    function _startGas() private {
        _gasIdx = gasleft();
        vm.resumeGasMetering();
    }

    function _stopGas() private returns (uint256 gasUsed) {
        unchecked { gasUsed = _gasIdx - gasleft(); }
        vm.pauseGasMetering();
    }

    function testGas_push() external gasTest {
        LL memory ll;
        _startGas();
        unchecked {
            for (uint256 i; i < NUM_SAMPLES; ++i) {
                ll.push(DUMMY_DATA_PTR);
            }
        }
        uint256 gasUsed = _stopGas();
        emit log_named_uint('gas per push()', gasUsed / NUM_SAMPLES);
    }

    function testGas_unshift() external gasTest {
        LL memory ll;
        _startGas();
        unchecked {
            for (uint256 i; i < NUM_SAMPLES; ++i) {
                ll.unshift(DUMMY_DATA_PTR);
            }
        }
        uint256 gasUsed = _stopGas();
        emit log_named_uint('gas per unshift()', gasUsed / NUM_SAMPLES);
    }

    function testGas_pop() external gasTest {
        LL memory ll = _createList(NUM_SAMPLES);
        _startGas();
        unchecked {
            for (uint256 i; i < NUM_SAMPLES; ++i) {
                ll.pop();
            }
        }
        uint256 gasUsed = _stopGas();
        emit log_named_uint('gas per pop()', gasUsed / NUM_SAMPLES);
    }

    function testGas_shift() external gasTest {
        LL memory ll = _createList(NUM_SAMPLES);
        _startGas();
        unchecked {
            for (uint256 i; i < NUM_SAMPLES; ++i) {
                ll.shift();
            }
        }
        uint256 gasUsed = _stopGas();
        emit log_named_uint('gas per shift()', gasUsed / NUM_SAMPLES);
    }

    function testGas_consecutiveLookupInAt() external gasTest {
        uint256 n = 64;
        LL memory ll = _createList(n);
        uint256 totalGasUsed;
        unchecked {
            for (uint256 i; i < n; ++i) {
                _startGas();
                ll.at(i);
                uint256 gasUsed = _stopGas();
                if (i < n / 2) {
                    totalGasUsed += gasUsed / (i + 1);
                } else {
                    totalGasUsed += gasUsed / (n / 2);
                }
            }
        }
        emit log_named_uint('gas per consecutive lookup in at()', totalGasUsed / n);
    }

    function _fib(uint256 n) private pure returns (uint256 r) {
        for (uint256 i; i < n; ++i) {
            r += (i + 1);
        }
    }

    function testMem_perItem() external {
        uint256 memUsage;
        assembly ("memory-safe") { memUsage := mload(0x40) }
        _createList(1024);
        assembly ("memory-safe") { memUsage := sub(mload(0x40), memUsage) }
        emit log_named_uint('mem usage per item (bytes)', memUsage / 1024);
    }

    function _createList(uint256 size) private pure returns (LL memory ll) {
        unchecked {
            for (uint256 i; i < size; ++i) {
                ll.push(DUMMY_DATA_PTR);
            }
        }
    }
}
