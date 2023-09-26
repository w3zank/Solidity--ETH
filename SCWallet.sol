// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract consumer {
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable{}
}

contract SmartContractWallet {

    //owner's address is payable; can receive funds on address type owner
    address payable public owner;
    
    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    //gaurdian mapping to set new address if funds are lost
    mapping(address => bool) public gaurdian;

    //3 out of minimum 5 gaurdians can confirm the authority of the previous owner
    //next owner rightfully inherits account 
    address payable nextOwner;
    mapping(address => mapping(address =>bool)) nextOwnerVoted;
    uint gaurdianResetCount;
    uint public constant gaurdianConfirmations = 3; 

    constructor() {
        //cast payable type onto 'msg.sender' address
        owner = payable(msg.sender);
    }

    function proposeNewOwner(address payable _newOwner) public {
        //check if addresss proposing new owner is gaurdian
        require(gaurdian[msg.sender], "You are not the gaurdian, owner has not set address as gaurdian");
        //check if the gaurdian (msg.sender) has already voted for _newOwner.
        require(nextOwnerVoted[_newOwner][msg.sender] == false , "Aborting, already voted");

        if(_newOwner != nextOwner){ //make sure next owner is not current address - confirms new proposal being made
           nextOwner = _newOwner;   //set the nextOwner as new proposed Owner
           gaurdianResetCount=0;   //reset the number of gaurdians to 0 after new owner - for further 3 confirmations
        }

        gaurdianResetCount++;

        if(gaurdianResetCount >= gaurdianConfirmations) {
            owner =  nextOwner;
            nextOwner = payable(address(0));
        }

    }
   

    //setting address as gaurdian owner, only done by owner themselves.
    //can remove (false) or add (true) gaurdian for specific address (_gaurd)
    function addGaurdian(address _gaurd, bool isGaurd) public {
        require(msg.sender == owner, "You are not the owner");
        gaurdian[_gaurd] = isGaurd;
    }
    
    //Owner can set allowance amount and bool permission by entering amount that "for" could send
    function setAllowance(address _for, uint amount) public {
        require(msg.sender == owner, "aborting, permission not granted");
        allowance[_for] = amount;

        if(amount > 0 ){ //if "for" has more than 0, then they have permission to send
            isAllowedToSend[_for] = true;
        }else{
            isAllowedToSend[_for] = false;
        }

    }

    function transfer(address payable _to, uint amount, bytes memory payload) public returns(bytes memory) {
        //require(msg.sender==owner, "You are not the owner");
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender] , "transfer aborted, no permission to send");
            require(allowance[msg.sender] >= amount, "transfer aborted, not enough funds");
            
        }

        (bool success, bytes memory data) = _to.call{value: amount}(payload);
        require(success, "call to target contract aborted");
        return data;
    }

    //fallback function; receive funds in all cases
    receive() external payable {}

}