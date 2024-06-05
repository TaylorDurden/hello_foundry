import "forge-std/Test.sol";
import {Event} from "../src/Event.sol";

// forge test --match-path test/Event.t.sol -vvvv

contract EventTest is Test {
    Event public e;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function setUp() public {
        e = new Event();
    }

    function testEmitTransferEvent() public {
        // function expectEmit(
        //     bool checkTopic1,
        //     bool checkTopic2,
        //     bool checkTopic3,
        //     bool checkData
        // ) external;

        // 1. Tell Foundry which data to check
        // Check index 1, index 2 and data
        vm.expectEmit(true, true, false, true);
        // 2. Emit the expected event
        emit Transfer(address(this), address(123), 456);
        // 3. Call the function that should emit the event
        e.transfer(address(this), address(123), 456);

        // Check only index 1
        vm.expectEmit(true, false, false, false);
        emit Transfer(address(this), address(123), 456);
        // NOTE: index 2 and data (amount) doesn't match
        //       but the test will still pass
        e.transfer(address(this), address(111), 222);
    }

    function testEmitManyTransferEvent() public {
        address[] memory toAddrs = new address[](2);
        toAddrs[0] = address(0);
        toAddrs[1] = address(1);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 666;
        amounts[1] = 888;

        for (uint256 i; i < toAddrs.length; i++) {
            vm.expectEmit(true, true, false, true);
            emit Transfer(address(this), toAddrs[i], amounts[i]);
        }

        e.transferMany(address(this), toAddrs, amounts);
    }
}
