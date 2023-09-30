// SPDX-License-Identifier: MIT

/*    ------------ External Imports ------------    */
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

pragma solidity ^0.8.0;

contract Lottery is VRFConsumerBaseV2 {
    /*    ------------ State Variables ------------    */

    /// @notice Chainlink VRF Coordinator Config for Sepolia Testnet
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public subscriptionId;
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256 public lotteryCount = 0;

    struct LotteryData {
        address lotteryOperator;
        address lotteryWinner;
        address[] tickets;
    }

    struct LotteryStatus {
        uint256 lotteryId;
        bool fulfilled;
        bool exists;
        uint256[] randomNumber;
    }

    mapping(uint256 => LotteryData) public lottery;
    mapping(uint256 => LotteryStatus) public requests;

    /*    ------------ Constructor ------------    */

    constructor(uint64 _subscriptionId, address _vrfCoordinator, bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
    }

    /*    ------------ Events ------------    */

    /// @notice Emitted when a new lottery is created
    event LotteryCreated(address lotteryOperator);

    /// @notice Emitted when a user buys tickets
    event TicketsBought(address buyer, uint256 lotteryId, uint256 ticketsBought);

    /// @notice Emitted when a Random Number Request is sent to Chainlink VRF
    event LotteryWinnerRequestSent(uint256 lotteryId, uint256 requestId, uint32 numWords);

    /// @notice Emitted when a Random Number Request is fulfilled by Chainlink VRF
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    /// @notice Emitted when a lottery winner is drawn
    event LotteryWinnerDrawn(uint256 lotteryId, address lotteryWinner);

    /*    ------------ Modifiers ------------    */

    modifier onlyOperator(uint256 _lotteryId) {
        require(
            (msg.sender == lottery[_lotteryId].lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    /*    ------------ Write Functions ------------    */

    /// @notice Creates a new lottery
    /// @param _lotteryOperator The address of the lottery operator
    function createLottery(address _lotteryOperator) public {
        require(_lotteryOperator != address(0), "Lottery operator cannot be 0x0");
        address[] memory ticketsArray;
        lotteryCount++;
        lottery[lotteryCount] = LotteryData({
            lotteryOperator: _lotteryOperator,
            lotteryWinner: address(0),
            tickets: ticketsArray
        });
        emit LotteryCreated(_lotteryOperator);
    }

    /// @notice Buys tickets for a lottery
    /// @param _lotteryId The id of the lottery
    /// @param _tickets The number of tickets to buy
    function buyTickets(uint256 _lotteryId, uint256 _tickets) public {
        require(_tickets > 0, "Number of tickets must be > 0");

        LotteryData storage currentLottery = lottery[_lotteryId];

        for (uint256 i = 0; i < _tickets; i++) {
            currentLottery.tickets.push(msg.sender);
        }

        emit TicketsBought(msg.sender, _lotteryId, _tickets);
    }

    function getTickets(uint256 _lotteryId) public view returns(address[] memory tickets) {
        return lottery[_lotteryId].tickets;
    }

    /// @notice Draws a lottery winner(only Lottery Operator can call this function)
    /// @param _lotteryId The id of the lottery
    /// @dev Sends a random number request to Chainlink VRF and returns the requestId
    function drawLotteryWinner(
        uint256 _lotteryId
    ) external onlyOperator(_lotteryId) returns (uint256 requestId) {
        require(lottery[_lotteryId].lotteryWinner == address(0), "Lottery winner already drawn");
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requests[requestId] = LotteryStatus({
            lotteryId: _lotteryId,
            randomNumber: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        emit LotteryWinnerRequestSent(_lotteryId, requestId, numWords);
        return requestId;
    }

    /*    ------------ Internal Functions ------------    */

    /// @notice Callback function used by VRF Coordinator
    /// @param _requestId - id of the request
    /// @param _randomWords - array of random values from VRF Coordinator
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(requests[_requestId].exists, "Error: Request not found");
        uint256 lotteryId = requests[_requestId].lotteryId;
        requests[_requestId].fulfilled = true;
        requests[_requestId].randomNumber = _randomWords;
        uint256 winnerIndex = _randomWords[0] % lottery[lotteryId].tickets.length;
        lottery[lotteryId].lotteryWinner = lottery[lotteryId].tickets[winnerIndex];
        emit RequestFulfilled(_requestId, _randomWords);
    }
}
