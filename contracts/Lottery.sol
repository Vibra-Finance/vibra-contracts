// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IRandomNumGen.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SafeMath16.sol";
import "./SafeMath8.sol";


contract VibraLotto is Ownable  {

     using SafeMath for uint256;

     using SafeMath16 for uint16;
     using SafeMath8 for uint8;
    

     using Address for address;


    

    // State variables 
    // Instance of Cake token (collateral currency for lotto)
    IERC20 internal vibra_;
    // Storing of the NFT
 
    IRandomNumberGenerator internal randomGenerator_;
    // Request ID for random number
    bytes32 internal requestId_;
    // Counter for lottery IDs 
    uint256 private lotteryIdCounter_;

    // Lottery size
    uint8 public sizeOfLottery_;
    // Max range for numbers (starting at 0)
    uint16 public maxValidRange_;
    // Buckets for discounts (i.e bucketOneMax_ = 20, less than 20 tickets gets
    // discount)
    uint8 public bucketOneMax_;
    uint8 public bucketTwoMax_;
   

    // Represents the status of the lottery
    enum Status { 
        NotStarted,     // The lottery has not started yet
        Open,           // The lottery is open for ticket purchases 
        Closed,         // The lottery is no longer open for ticket purchases
        Completed       // The lottery has been closed and the numbers drawn
    }
    // All the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryID;          // ID for lotto
        Status lotteryStatus;       // Status for lotto
        uint256 prizePoolInVibra;    // The amount of cake for prize money
        uint256 costPerTicket;      // Cost per ticket in $vibra
        uint8[] prizeDistribution;  // The distribution for prize money
        uint256 startingTimestamp;      // Block timestamp for star of lotto
        uint256 closingTimestamp;       // Block timestamp for end of entries
        uint16[] winningNumbers;     // The winning numbers
    }
    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries_;

     modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator_),
            "Only random generator"
        );
        _;
    }

     constructor(
        address _vibra, 
        
        uint8 _sizeOfLotteryNumbers,
        uint16 _maxValidNumberRange
       
       
    ) 
        
        public
    {
        
        
        
        require(
            _vibra != address(0),
            "Contracts cannot be 0 address"
        );
        require(
            _sizeOfLotteryNumbers != 0 &&
            _maxValidNumberRange != 0,
            "Lottery setup cannot be 0"
        );
        vibra_ = IERC20(_vibra);
        sizeOfLottery_ = _sizeOfLotteryNumbers;
        maxValidRange_ = _maxValidNumberRange;
        
        
        
    }

    function costToBuyTickets(uint256 _lotterId, uint256 _numberOfTickets) external view returns(uint256 totalCost) {
        uint256 pricePer = allLotteries_[_lotterId].costPerTicket;
        totalCost = pricePer.mul(_numberOfTickets);
    }

    function getBasicLottoInfo(uint256 _lotterId) external view returns(LottoInfo memory) {
        return(allLotteries_[_lotterId]);

    }

    function getMaxRange() external view returns(uint16) {
        return maxValidRange_;
    }

    function UpdateSizeOflottery(uint8 _newSize) external onlyOwner() {
        require(sizeOfLottery_ != _newSize, "Cannot set to current size");
        require(sizeOfLottery_ != 0, "Lotto size cannot be 0");
        sizeOfLottery_ = _newSize;
    }

     function updateMaxRange(uint16 _newMaxRange) external onlyOwner {
        require(maxValidRange_ != _newMaxRange, "Cannot set to current size");
        require(maxValidRange_ != 0, "Max range cannot be 0");
        maxValidRange_ = _newMaxRange;
    }

    function drawWinningNumbers(uint256 _lotteryId, uint256 _seed) external onlyOwner() {
        require(allLotteries_[_lotteryId].closingTimestamp <= block.timestamp, "Cannot set winning numbers during lotto");
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Open);
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Closed);
        requestId_ = randomGenerator_.getRandomNumber(_lotteryId, _seed);
        

    }

    function numberDrawn(uint256 _lotteryId, bytes32 _requestId, uint256 _randomNumber) external onlyRandomGenerator() {
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Closed, "Draw numbers first");
        if(requestId_ == _requestId){
            allLotteries_[_lotteryId].lotteryStatus = Status.Completed;
            allLotteries_[_lotteryId].winningNumbers = _split(_randomNumber);
        }
    }
    
    
    function createNewLotto(uint8[] calldata _prizeDistribution, uint256 _prizePoolInVibra, uint256 _costPerTicket, uint256 _startingTimeStamp, uint256 _closingTimeStamp) external onlyOwner()  returns(uint256 lotteryId) {
        require(_prizeDistribution.length == sizeOfLottery_, "Invalid distribution");
        uint256 prizeDistributionTotal = 0;
        for (uint j = 0; j < _prizeDistribution.length; j++) {
            prizeDistributionTotal = prizeDistributionTotal.add(uint256(_prizeDistribution[j]));
        }
        require(prizeDistributionTotal == 100, "Prize distribution is not 100%");
        require(_prizePoolInVibra != 0 && _costPerTicket != 0, "Prize or cost cannot be 0");
        require(_startingTimeStamp != 0 && _startingTimeStamp < _closingTimeStamp, "Timestamp for lottery invalid");
        lotteryIdCounter_ = lotteryIdCounter_.add(1);
        lotteryId = lotteryIdCounter_;
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        Status lotteryStatus;
        if(_startingTimeStamp >= block.timestamp) {
            lotteryStatus = Status.Open;

        } else {
            lotteryStatus = Status.NotStarted;
        }
        LottoInfo memory newLottery = LottoInfo(lotteryId, lotteryStatus, _prizePoolInVibra, _costPerTicket, _prizeDistribution, _startingTimeStamp,_closingTimeStamp, winningNumbers);
        allLotteries_[lotteryId] = newLottery;


    }

    function withdrawVibra(uint256 _amount) external onlyOwner() {
        vibra_.transfer(msg.sender, _amount);
    }

    

    function _getNumberOfMatching(uint16[] memory _userNumbers, uint16[] memory _winningNumbers) internal pure returns(uint8 noOfmatching) {
        for (uint256 i = 0; i < _winningNumbers.length; i++) {
            if(_userNumbers[i] == _winningNumbers[i]) {
                noOfmatching += 1;
            }
        }
    }

    function _prizeForMatching(uint8 _noOfMatching, uint256 _lotteryId) internal view returns(uint256) {
        uint256 prize = 0;
        if(_noOfMatching == 0) {
            return 0;
        }
        uint256 perOfPool = allLotteries_[_lotteryId].prizeDistribution[_noOfMatching-1];
        prize = allLotteries_[_lotteryId].prizePoolInVibra.mul(perOfPool);
        return prize.div(100);
    }

    function _split(uint _randomNumber) internal view returns(uint16[] memory) {
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        for(uint i = 0; i < sizeOfLottery_; i++){
            bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber, i));
            uint256 numberRepresentation = uint256(hashOfRandom);
            winningNumbers[i] = uint16(numberRepresentation.mod(maxValidRange_));
        }
        return winningNumbers;
    }








}




