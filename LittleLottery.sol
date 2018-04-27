pragma solidity ^0.4.18;

contract LittleLottery {
    
    address public runner;
    bool public refunded;
    bool public complete;
    uint public numGamblers;
    uint private numWinners;
    uint public minimumBet;
    uint private totalBonus;
    string public promotemsg;
    
    uint private c_rate;
    uint private commision;

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
    
    //Constructor
    function LittleLottery(string _promotemsg, uint _minimumBet) payable public{
        
        require(msg.value >= 50 * 1 ether);
        runner = msg.sender;
        numGamblers = 0;
        numWinners = 0;
        commision = 0;
        c_rate = 10;
        refunded = false;
        complete = false;
        minimumBet = _minimumBet;
        totalBonus = msg.value; 
        promotemsg = _promotemsg;
    }
    
    //get totalBonus
    function getCurrentTotalBonus() public constant returns(uint) {
        return totalBonus / 1 ether;
    }
    
    //add a new gamblers
    function gamble(uint _selectedNum) payable requiredminimumBet public{
        require(msg.value != 0 && !complete && !refunded);
        require(_selectedNum > 0 && _selectedNum <= 50);
        require(msg.sender != runner);
        
        //seperate commision, set each minimumBet has at least 1 comission
        uint temp = msg.value * c_rate / 100;
        if(temp < 1) temp = 1;
        commision += temp;

        gamblers[numGamblers] = Gambler(msg.value, msg.sender, _selectedNum);
        numGamblers++;
        totalBonus += (msg.value - temp);
    }
    
    //draw winning number
    function draw(uint _lotteryNum) public onlyrunner {
        require(!complete && !refunded);

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
             
        complete = true;
        endcontract();
    }
    
    //refund to gamblers
    function refund() onlyrunner private{
        
        for(uint i = 0; i < numGamblers; i++){
            gamblers[i].eth_address.transfer(gamblers[i].amount);
        }
        
        refunded = true;
        complete = true;
        endcontract();
    }

    function endcontract() private onlyrunner{
        runner.transfer(address(this).balance);
    }
}