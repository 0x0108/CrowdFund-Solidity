pragma solidity >=0.5.0 <0.9.0;

/*This is crowd funding contract, aims to collect funds from multiple wallet, it has a target and a dedline, 
the manager of the contract can submit request of the beneficiary wallet, amount required and the purpose.
Now fund contributoers will be able to vote. The project which recived highest no of votes will get the funds allocated to them by the contract */
contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    // Structs defines the required parameters when the contract managed decides to submit
    struct Request {
        string description;
        address payable recepient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    // mapping of request no to request details
    mapping(uint => Request) public requests;
    uint public numRequests;

    // This const takes the target and deadline during the deployment

    constructor(uint _target, uint _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    // This fn is called by the crowd fund contributer to provide funds to the pool

    function sendEth() public payable {
        require(block.timestamp < deadline, "You are late deadline is over");
        require(msg.value >= minimumContribution, "Send at least 100 wei");

        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function refund() public {
        require(
            block.timestamp > deadline && raisedAmount > target,
            "Your contribution is accepted"
        );
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You are not a manager");
        _;
    }

    function createRequests(
        string memory _description,
        address payable _recepient,
        uint _value
    ) public onlyManager {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recepient = _recepient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public {
        require(
            contributors[msg.sender] > 0,
            "You are not a contributer, not eligible for voting"
        );
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "Your vote is done");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public {
        require(raisedAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "You have been paid already");
        require(
            thisRequest.noOfVoters > noOfContributors / 2,
            "You dont have majority"
        );
        thisRequest.recepient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
