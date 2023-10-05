// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;


contract LotteryPot {

    address payable lotteryPurse;
    uint256 ticketPrice = 1 ether;
    uint ticketCount;

    uint public nonce;

    struct ticket {
        uint Tid;
        address Tpurchaser;
        uint256 purchaseTime;
    }

    address[] public purchasers;

    mapping(uint => ticket) IdPurchasedTicket;
    mapping(address => uint[]) addressPurchasersTicket;  

    constructor() {
        lotteryPurse = payable(msg.sender);
    }

    //total contribution
    function getPotBalance() public view returns(uint) {
        return address(this).balance;
    }

    //dispersePrize
    function sendPrize() public  {
        uint winner = randomSelection();
        uint256 winAmount = (address(this).balance * 80)/100;
        payable(purchasers[winner]).transfer(winAmount);

    }

    function randomSelection() private returns(uint) {
        //require(msg.sender == lotteryPurse, "You cannot proceed with following action");
        uint winIndex;
        
        //encode timestamp, difficulty, address and nonce to gain a unique uint256 seed
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            blockhash(block.number - 1), //previous block number hash (prevrandao)
            msg.sender,
            nonce
        )));
        nonce++; //nonce incremented for randomness
        winIndex = randomSeed % ticketCount;

        return winIndex;
    }

    //called externally trhough receive fallback
    function deposit() public payable {
        require(msg.value>=ticketPrice, "deposit aborted; Not enough funds");
        //total tickets purchased; increment ticketCount & assign count as ID into struct
        ticketCount += msg.value/(ticketPrice);
        //in case of multiple purchases; for loop will run to assign appropriate ID a users ticket(s)
        for(uint i=ticketCount-(msg.value/ticketPrice); i<ticketCount; i++){
        IdPurchasedTicket[i] = ticket(i, msg.sender, block.timestamp);
        addressPurchasersTicket[msg.sender].push(i);
        purchasers.push(msg.sender);
        }
        

    }

    receive() external payable  {
        deposit();
    }

    function getTicketPrice() public view returns(uint256) {
        return ticketPrice;
    }

    function getUserTickets(address purchaser) external view returns (uint[] memory) {
        return addressPurchasersTicket[purchaser];
    }
  

}

/*testing purchaser: Remaining Functionality: */
   
interface lotpot { 
    function getTicketPrice() external view returns(uint256); 
}

contract purchaser1{
    lotpot public lotteryContract;
    address participant;
    mapping(address =>bool) public paymentReceived;

    constructor(address _lotpotAddr) {
        lotteryContract = lotpot(_lotpotAddr);
        participant = msg.sender;
    }

    uint[] tickets;

    function deposit() public payable {}
    
    receive() external payable{
        //mark paymentReceived as true when lottery prize is distributed;
        paymentReceived[msg.sender] = true;
    }

    function purchaseTicket(uint _tickets) public payable {
        require(msg.sender==participant, "ABORTED, you cannot purchase from this contract");
        require(address(this).balance >= _tickets * getTicketPrice(), "Insufficient Ether");

        uint256 totalCost = _tickets * getTicketPrice();

        (bool success, ) = address(lotteryContract).call{value: totalCost, gas:10000000}("");
        require(success, "Transaction Aborted");

    }

    function getTicketPrice() public view returns(uint) {
        require(msg.sender==participant, "ABORTED, you cannot purchase from this contract");
        return lotteryContract.getTicketPrice();
    }

    function withdrawPrize() public {
        require(msg.sender==participant, "ABORTED, you cannot withdraw from this contract");
        require(paymentReceived[msg.sender] = true, "ABORTED, you did not receive the prize");
        //cast payable onto participant address and transfer entire balance of purchaser contract
        payable(participant).transfer(address(this).balance);
    }

    /*function getPurchaserTickets(address purchaser) external view returns (uint[] memory) {
        
    }*/
}

   
/* created by: AZAN HYDER - 10/3/2023 */
  
// feel free to make changes within code for added functionality and let me know for updates //  