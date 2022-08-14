
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'src/ExternalStrategy/UniversalParser.sol';

contract UniversalParserTest is Test {
  enum Actions {
      Enter,
      Reduce,
      Config,
      AdminExecute,
      AdminWithdraw
  }
  address constant externalStrategy = address(1922);
  UniversalParser parser;
  
  function encodeActionsHelper(address _toTransfer, uint256 _amount, address _toReceive) public pure returns (bytes memory encoded) {
    address[] memory toTransfers = new address[](1);
    toTransfers[0] = _toTransfer;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = _amount;
    address[] memory toReceives = new address[](1);
    toReceives[0] = _toReceive;
    return abi.encode(toTransfers, amounts, toReceives);
  }

  function setUp() public {
    parser = new UniversalParser();
  }

  function testParseUnsupportedAction() public {
    vm.expectRevert(bytes('receiveCallFromVault: Invalid actionId'));
    parser.parseAssetsForAction(
      externalStrategy,
      5,
      encodeActionsHelper(address(1), 1000, address(1))
    );
  }

  function testParseEnterAction() public {
    bytes memory expectedInput = encodeActionsHelper(address(1), 1000, address(1));
    vm.mockCall(
      externalStrategy,
      abi.encodeWithSignature("parseEnter(bytes)", expectedInput),
      expectedInput
    );
    (address[] memory rtransfers, uint256[] memory ramounts, address[] memory rreceives) = parser.parseAssetsForAction(
      externalStrategy,
      0,
      expectedInput
    );
    assertEq(expectedInput, abi.encode(rtransfers, ramounts, rreceives));
  }

  function testParseReduceAction() public {
    bytes memory expectedInput = encodeActionsHelper(address(1), 1000, address(1));
    vm.mockCall(
      externalStrategy,
      abi.encodeWithSignature("parseReduce(bytes)", expectedInput),
      expectedInput
    );
    (address[] memory rtransfers, uint256[] memory ramounts, address[] memory rreceives) = parser.parseAssetsForAction(
      externalStrategy,
      1,
      expectedInput
    );
    assertEq(expectedInput, abi.encode(rtransfers, ramounts, rreceives));
  }

  function testParseAdminExecute() public {
    bytes memory expectedInput = encodeActionsHelper(address(1), 1000, address(1));
    vm.mockCall(
      externalStrategy,
      abi.encodeWithSignature("parseAdminExecute(bytes)", expectedInput),
      expectedInput
    );
    (address[] memory rtransfers, uint256[] memory ramounts, address[] memory rreceives) = parser.parseAssetsForAction(
      externalStrategy,
      3,
      expectedInput
    );
    assertEq(expectedInput, abi.encode(rtransfers, ramounts, rreceives));
  }

  function testConfig() public {
    bytes memory expectedInput = encodeActionsHelper(address(1), 1000, address(1));
    // config action should not return any fields
    (address[] memory rtransfers, uint256[] memory ramounts, address[] memory rreceives) = parser.parseAssetsForAction(
      externalStrategy,
      2,
      expectedInput
    );
    address[] memory nullTransfers = new address[](0);
    uint256[] memory nullAmounts = new uint256[](0);
    address[] memory toReceives = new address[](0);
    assertEq(nullTransfers, rtransfers);
    assertEq(nullAmounts, ramounts);
    assertEq(toReceives, rreceives);
  }

  function testAdminWithdraw() public {
  }
}
