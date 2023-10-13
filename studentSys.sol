// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract studentRegister{

    address admin;
    uint idCount=100;
    student[] public  studentArr;

    struct student {
        //ID
        uint std_id;
        //NAME
        string name;
        //DOB
        dateOfBirth dob;
        //dept
        string studentDepartment;
        //registration bool
        bool registered;
    }

    struct dateOfBirth {
        uint year;
        uint month;
        uint day;
    }

    mapping(uint => student) studentID;

    

    constructor() {
        //admin deploys contract initally; permission only granted to them
        admin = msg.sender;
    }

    //check if student is 17-24 y/o
    function checkDob(dateOfBirth memory _dob) public view returns(bool)  {
        uint currentYear = (block.timestamp / 365 days) + 1970;
        require(currentYear - _dob.year >= 17 && currentYear - _dob.year < 25, "student cannot be enrolled");
        return true;
    }

    //add student funciton
    function addStudent(string memory _name, uint _year, uint _month, uint _day, string memory _deptName) external  {
        require(msg.sender == admin, "only admin has permission, ABORTED");
        require(checkDob(dateOfBirth(_year, _month, _day)), "Must be age of 17 to 24, ABORTED");
        //construct dob and contruct student
        dateOfBirth memory _dob= dateOfBirth(_year, _month, _day);
        student memory _student= student(idCount, _name, _dob, _deptName, true);

        studentID[idCount] = _student;
        studentArr.push(_student);
        idCount++;
    }
    
    //removing student results in loss of IDcount and has to be re-registered with new id!
    function removeStudent(uint student_id) public {
        for(uint i=0; i<studentArr.length; i++)
        {
            if(studentArr[i].std_id == student_id){ //check if student ids match
            //replace the matching id with the last element in the array

            if(i<studentArr.length-1){//if matching id is not the last one
            //swap last one with matching id
            student memory tempst = studentArr[i];
            studentArr[i] = studentArr[studentArr.length-1];
            studentArr[studentArr.length-1] = tempst;
            }
            studentArr[studentArr.length-1].registered = false;
            studentArr.pop();
            return;
            }
        } revert("student not found");
    } 

    
    function viewStudents() public view returns (student[] memory){
        require(msg.sender==admin,"only admin has permission, ABORTED");
        return studentArr;
    }

    //edit options
    enum editField {name, year, month, day, dept}
    //edit function 
    function editStudent(uint _id, editField _edit, string memory _toNew) public {
        require(msg.sender==admin, "only admin has permission, ABORTED");
       
        require(_id < idCount, "student not found");

        if(_edit == editField.name) {
            studentID[_id].name = _toNew;
        }
        else if (_edit == editField.year) {
            studentID[_id].dob.year = parseInt(_toNew);
        } 
        else if (_edit == editField.month) {
            studentID[_id].dob.month = parseInt(_toNew);
        } 
        else if (_edit == editField.day) {
           studentID[_id].dob.day = parseInt(_toNew);
        }else if (_edit == editField.dept){
            studentID[_id].studentDepartment = _toNew;
        }
        else{
            revert("invalid edit field");
        }

        for(uint i=0; i<studentArr.length; i++) {
            if(studentArr[i].std_id==_id) {
                studentArr[i] = studentID[_id];
            }else{
                revert("student was removed; re-registered with newID");
            }
        }
        
    }

//parseInt functionality to ensure string to uint conversion using bytes types
    function parseInt(string memory _value) internal pure returns (uint) {
    uint result = 0;
    bytes memory valueBytes = bytes(_value);
    for (uint i = 0; i < valueBytes.length; i++) {
        uint8 digit = uint8(valueBytes[i]);
        require(digit >= 48 && digit <= 57, "Invalid character in string"); // Check if it's a valid digit
        result = result * 10 + uint(digit - 48);
    }
    return result;
}



    

    



    

    
}