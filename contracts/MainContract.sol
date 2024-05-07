// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16 <0.6.0;
import "./IERC20.sol";

// This contract is a smart contract for buying and selling transactions that uses the IERC20 contract to interact with ERC20 tokens.
contract MainContract {
    IERC20 public usdt; // Variable to store the address of the ERC20 token
    uint256 public referenceDate; // Reference time for calculating periods
    uint256 public secondsInADay = 86400; // Number of seconds in a day
    uint256 public halfSecondsInADay = 43200; // Half of the number of seconds in a day
    uint8 public period = 5; // Transaction period
    mapping (address => bytes32) public purchaseHashesRoot; // Map to store the Merkle tree roots of users' purchases
    mapping (address => mapping (uint256 => uint256)) public conditionalTokens; // Map to store conditional token values
    mapping (address => bool) public blockedAddresses; // Map to store the blocked status of addresses
    // Event emitted when a purchase is created
    event purchase(address indexed seller, address buyer,uint purchaseID,uint256 price, uint256 deliverTime, bytes32 hashRandomNumber);
     // Struct to store complaint details
    struct complaint {
        uint purchaseID; // ID of the purchase
        bytes32 complaintHash; // Hash of the random number
        uint256 complaintDeliveryTime; // Delivery time
        uint256 complaintTime; // Time of the complaint
    }

    // Mapping to store complaints, indexed by buyer and seller addresses
    mapping (address => mapping (address => complaint)) complaints;

    // Event emitted when a complaint is recorded
    event recordComplaint(address indexed seller, address plaintiff, uint purchaseID, bytes32 hashComplaint, uint256 deliverTime);
    // Constructor method where the token address and initial transaction period are set
    constructor(uint8 _period, address _usdtAddress) public{
        usdt = IERC20(_usdtAddress);
        referenceDate = block.timestamp;
        period = _period;
    }

    // Function to create a purchase
    function CreatePurchase(uint purchaseID, uint256 price, uint256 deliverTime, address seller, bytes32 hashRandomNumber, bytes32[] calldata hashes) external  returns (bool){
        require(deliverTime - block.timestamp <= period * secondsInADay, "Deliver time is late"); // Check if the delivery time is appropriate
        require(!blockedAddresses[msg.sender], "Your address is blocked"); // Check if the user's address is blocked
        require(usdt.transfer(address(this), price), "Purchase Failed"); // Transfer the required tokens for purchase to the contract
        bytes32  hashResult = keccak256(abi.encodePacked(purchaseID, price, deliverTime, seller, hashRandomNumber)); // Calculate the hash of purchase information
        for (uint256 i = 0; i < hashes.length; i++){
            hashResult = keccak256(abi.encodePacked(hashResult, hashes[i])); // Create the Merkle tree hash
        }
        purchaseHashesRoot[msg.sender] = hashResult; // Store the Merkle tree root in the map
        uint256 time = ((deliverTime - referenceDate) / secondsInADay); // Calculate time in periods
        uint256 account = (time + period + 2 ) % (period + 3);
        conditionalTokens[seller][account] += price; // Add the conditional token amount to the map
        emit purchase(seller,msg.sender,purchaseID,price,deliverTime,hashRandomNumber); // Emit an event for the created purchase
        return true;
    }
    function _withdraw(address reciever, uint256 amount) private returns(bool){
        usdt.transferFrom(address(this), reciever, amount);
        return true;
    }
    // Function for submitting a complaint
    function SubmitComplaint(bytes32 hashRandomNumber, address seller, uint purchaseID, uint256 deliverTime) external returns (bool){
        require(!blockedAddresses[msg.sender], "Your address is blocked"); // Check if the user's address is blocked
        require(deliverTime < block.timestamp && block.timestamp - deliverTime < halfSecondsInADay ,"The time is soon"); // Check if the complaint time is appropriate
        complaints[msg.sender][seller] = complaint(purchaseID, hashRandomNumber, deliverTime, block.timestamp); // Record the complaint
        emit recordComplaint(seller, msg.sender, purchaseID, hashRandomNumber, deliverTime); // Emit an event for the recorded complaint
        return true;
    }

    // Function for resolving a complaint
    function ResolveComplaint(uint256 price, address seller, bytes32[] calldata hashes) external returns (bool){
        require(!blockedAddresses[msg.sender], "Your address is blocked"); // Check if the user's address is blocked
        require(block.timestamp - complaints[msg.sender][seller].complaintTime > halfSecondsInADay, "The time is soon"); // Check if the complaint time has passed

        bytes32 hashRandomNumber = complaints[msg.sender][seller].complaintHash;
        uint256 deliverTime = complaints[msg.sender][seller].complaintDeliveryTime;
        uint purchaseID = complaints[msg.sender][seller].purchaseID;

        bytes32  hashResult = keccak256(abi.encodePacked(purchaseID, price, deliverTime, seller, hashRandomNumber));
        for (uint256 i = 0 ; i < hashes.length; i++){
            hashResult = keccak256(abi.encodePacked(hashResult, hashes[i]));
        }

        if (hashResult == purchaseHashesRoot[msg.sender]){
             uint256 time = ((deliverTime - referenceDate) / secondsInADay);
             uint256 account = (time + period + 2 ) % (period + 3);
             conditionalTokens[seller][account] -= price;
             return _withdraw(msg.sender, price);
        } else {
            return false;
        }
    }

    // Function for blocking invalid complaints
    function BlockInvalidComplaints(address plaintiff, address seller, bytes32 randomNumber) external returns (bool){
        require(block.timestamp - complaints[plaintiff][seller].complaintTime < halfSecondsInADay); // Check if the complaint time is within 12 hours

        bytes32 hashRandomNumber = keccak256(abi.encodePacked(keccak256(abi.encodePacked(randomNumber))));
        if (hashRandomNumber == complaints[plaintiff][seller].complaintHash){
            blockedAddresses[plaintiff] = true; // Block the plaintiff's address
            complaints[plaintiff][seller].complaintHash = bytes32(0); // Reset the complaint hash
            return true;
        } else {
            return false;
        }
    }
    // Function to withdraw funds
    function withdrawFunds() external returns (bool){
        // Calculate the current time in days since the reference date
        uint256 time = (block.timestamp - referenceDate) / secondsInADay;
        // Calculate the remainder of dividing the time by the period plus 3 (a grace period)
        uint256 account = time % (period + 3);
        // Get the amount of conditional tokens available for withdrawal
        uint256 amount = conditionalTokens[msg.sender][account];
        // Subtract the withdrawn amount from the seller's conditional tokens balance
        conditionalTokens[msg.sender][time] -= amount;
        // Transfer the withdrawn amount of USDT tokens from the Maincontract to the seller
        return _withdraw(msg.sender, amount);
    }
}
