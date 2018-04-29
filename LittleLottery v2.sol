pragma solidity ^0.4.18;

contract LittleLottery {
    
    address public runner;
    uint public numGamblers;
    uint public minimumBet;
    string public promotemsg;
    uint[2] public numberRange;
    uint public commisionRate;
    
    uint private commision;
    uint private numWinners;
    uint private totalBonus;



    enum State { active, refunded, complete }
    
    State private status;

    struct Gambler {
        uint amount;
        address eth_address;
        uint selectedNum;
    }
    
    struct Winner {
        address eth_address;
    }
    
    mapping(uint => Gambler) private gamblers;
    mapping(uint => Winner) public winners;
    
    modifier onlyrunner{
        require(msg.sender == runner);
        _;
    }
    
    modifier requiredminimumBet{
        require(msg.value >= minimumBet * 1 ether);
        _;
    }
    
    modifier inStatus(State _status){
        require(_status == status);
        _;
    }
    
    //Constructor
    function LittleLottery(string _promotemsg, uint _minimumBet, uint _minNumberRange, uint _maxNumberRange, uint _commisionRate) payable public{
        
        require(msg.value >= 50 * 1 ether);
        runner = msg.sender;
        numGamblers = 0;
        numWinners = 0;
        commision = 0;
        
        require(_commisionRate > 0 && _commisionRate < 100);
        commisionRate = _commisionRate;
        status = State.active;
        minimumBet = _minimumBet;
        totalBonus = msg.value; 
        promotemsg = _promotemsg;
        
        require(_minNumberRange>=1 &&_minNumberRange < _maxNumberRange);
        numberRange[0] = _minNumberRange;
        numberRange[1] = _maxNumberRange;
    }
    
    //get totalBonus
    function getCurrentTotalBonus() public constant returns(uint) {
        return totalBonus / 1 ether;
    }
    
    //get currentStatus
    function getStatus() public constant returns(string){
        if(status == State.active) return "active";
        else if(status == State.complete) return "complete";
        else if(status == State.refunded) return "refunded";
        else return "status error";
    }
    
    //add a new gamblers
    function gamble(uint _selectedNum) payable requiredminimumBet inStatus(State.active) public{
        require(msg.value != 0);
        require(_selectedNum >= numberRange[0] && _selectedNum <= numberRange[1]);
        require(msg.sender != runner);
        
        //seperate commision, set each minimumBet has at least 1 comission
        uint temp = msg.value * commisionRate / 100;
        if(temp < 1) temp = 1;
        commision += temp;

        gamblers[numGamblers] = Gambler(msg.value, msg.sender, _selectedNum);
        numGamblers++;
        totalBonus += (msg.value - temp);
    }
    
    //draw winning number
    function draw(uint _lotteryNum) public inStatus(State.active) onlyrunner {

        require(_lotteryNum >= numberRange[0] && _lotteryNum <= numberRange[1]);

        for(uint i = 0; i < numGamblers; i++){
            if(gamblers[i].selectedNum == _lotteryNum){
                winners[numWinners] = Winner(gamblers[i].eth_address);
                numWinners++;
            }
        }
        
        if(numWinners == 0){
            refund();
        }else{
            drawdown();
        }
    }
    
    //send fund to winner
    function drawdown() onlyrunner private{
        
        uint distributeAmt = totalBonus / numWinners;
        for(uint i = 0; i< numWinners; i++){
            winners[i].eth_address.transfer(distributeAmt); 
        }
             
        status = State.complete;
        endcontract();
    }
    
    //refund to gamblers
    function refund() onlyrunner private{
        
        for(uint i = 0; i < numGamblers; i++){
            gamblers[i].eth_address.transfer(gamblers[i].amount);
        }
        
        status = State.refunded;
        endcontract();
    }

    function endcontract() private onlyrunner{
        require(status == State.complete || status == State.refunded);
        runner.transfer(address(this).balance);
        
    }
}