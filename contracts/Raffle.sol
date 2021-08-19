// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;
import '@chainlink/contracts/src/v0.7/VRFConsumerBase.sol';
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract VibraRaf is VRFConsumerBase {

    AggregatorV3Interface internal ethUsd;
    uint internal fee;
    uint public randomResult;
//Network:
    address constant VRFC_address = ""; // VRF Coordinator
    address constant LINK_address = ""; // VRF Coordinator
   

    address payable public admin;

    //keyHash - one of the component from which will be generated final random value by Chainlink VFRC.
     bytes32 constant internal keyHash = "";



    uint private chosenNumber;
    address private winnerParticipant;
    uint8 maxParticipants;
    uint8 minParticipants;
    uint8 joinedParticipants;
    address organizer;

    bool raffleFinished = false;

    address[] participants;
    mapping (address => bool)
    participantsMapping;

    /**
   * Constructor inherits VRFConsumerBase.
   */

    constructor() VRFConsumerBase(VRFC_address, LINK_address) public {
        fee = 0.1 * 10 ** 18;
        admin = msg.sender;
        ethUsd = AggregatorV3Interface();

         /** !UPDATE
     * 
     * assign ETH/USD Rinkeby contract address to the aggregator variable.
     * more: https://docs.chain.link/docs/ethereum-addresses
     */



        

        

    }
     /** !UPDATE
   * 
   * Returns latest ETH/USD price from Chainlink oracles.
   */
 
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
     /** !UPDATE
   * 
   * Returns latest ETH/USD price from Chainlink oracles.
   */

    function ethInUsd() public views returns (int) {
        (uint roundId, int price, uint startedAT, uint timeStamp, uint80 answeredInRound) = ethUsd.latestRoundData();

        return price;
    }


    function Raffle() public {
        address _org = msg.sender;
        uint8 _min = 2;
        uint8 _max = 10;
        require(_min < _max && _min >=2 && _max <=50);
        
        organizer = _org;
        chosenNumber = 999;
        maxParticipants = _max;
        minParticipants  = _min;
    }

    function joinRaffle() public {
        require(!raffleFinished);
        require(msg.sender != organizer);
        require(joinedParticipants + 1 < maxParticipants);
        require(!participantsMapping[msg.sender]);

        participants.push(msg.sender);
        participantsMapping[msg.sender] = true;

        joinedParticipants ++;

    }

    function chooseWinner(uint _chosenNum) internal {
        chosenNumber = _chosenNum;
        winnerParticipant = participants[chosenNumber];
         ChooseWinner(chosenNumber,participants[chosenNumber]);
        
    }

    function getRandomNumber(uint256 userProvidedSeed) 

    


}
 
  
  