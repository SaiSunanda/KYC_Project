pragma solidity ^0.6.1;
pragma experimental ABIEncoderV2;

contract KYC {

    address admin;

    uint256 threshold = 500 finney;

    /*
    Struct for a customer
     */
    struct Customer {
        string userName;   //unique
        string password;
        string data_hash;  //unique
        uint8 rating;
        uint8 upvotes;
        address bank;
        address[] votedBankAddress;
    }

    /*
    Struct for a Bank
     */
    struct Bank {
        address ethAddress;   //unique
        string bankName;
        uint8 kycCount;
        uint8 bankRating;
        string regNumber;       //unique
        string[] kycRequestList;
        address[] bankVotedAddress;
    }

    /*
    Struct for a KYC Request
     */
    struct KYCRequest {
        string userName;
        string data_hash;  //unique
        address bank;
        bool isAllowed;
    }

    /*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => Customer) customers;
    string[] customerNames;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(address => Bank) banks;
    address[] bankAddresses;

    /*
    Mapping a customer's Data Hash to KYC request captured for that customer.
    This mapping is used to keep track of every kycRequest initiated for every customer by a bank.
     */
    mapping(string => KYCRequest) kycRequests;
    string[] customerDataList;

    string[] list;

    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer.
     */
    mapping(string => mapping(address => uint256)) upvotes;

    /*
    Mapping a bank name with another bank's name
    This mapping is used to keep track of every upvote given by a bank to another bank.
     */
    mapping(string => mapping(string => uint256)) bankRating;

    /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor() public {
        admin = msg.sender;
    }

    /**
     * Modifier for Admin interface
     * We use some functions which can be only used from admin interface.
     */
    modifier onlyOwner{
       require(msg.sender == admin,"You are not an Admin user");
       _;
    }

    /*
    *   //////////////
    *   Bank Interface
    *   //////////////
    */

    /**
     * Record a new KYC request on behalf of a customer
     * The sender of message call is the bank itself
     * @param {string} _userName The name of the customer for whom KYC is to be done
     * @param {string} _customerData Hash of the customer's ID submitted for KYC
     * @return {uint8}  0 indicates failure, 1 indicates success
     */
    function addKycRequest(string memory _userName, string memory _customerData) public returns (uint8) {
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.
        require(kycRequests[_customerData].bank == address(0), "This user already has a KYC request with same data in process.");

        uint8 x = banks[msg.sender].bankRating;
        if ( x > threshold ) {
            kycRequests[_customerData].isAllowed = true;

            for (uint i = 0; i < bankAddresses.length; i++) {
            if(bankAddresses[i] == msg.sender && kycRequests[_customerData].isAllowed) {
                kycRequests[_customerData].data_hash = _customerData;
                kycRequests[_customerData].userName = _userName;
                kycRequests[_customerData].bank = msg.sender;
                banks[msg.sender].kycRequestList.push(_customerData);
                customerDataList.push(_customerData);
                return 1;
           }
        }
        }else{
            return 0;
        }
    }

    /**
     * Remove KYC request
     * @param {string} _userName Name of the customer
     * @param {string} _customerData Hash of the customer's ID submitted for KYC
     * @return {uint8}  0 indicates failure, 1 indicates success
     */
    function removeKYCRequest(string memory _userName, string memory _customerData) public returns (uint8) {
        uint8 i = 0;
        for (uint256 y = 0; y < customerDataList.length; y++) {
            if (stringsEquals(kycRequests[customerDataList[y]].userName,_userName)) {
                delete kycRequests[customerDataList[y]];
                for(uint j = y+1;j < customerDataList.length;j++)
                {
                    customerDataList[j-1] = customerDataList[j];
                }
                y = 1;
            }
        }
        return i; // 0 is returned if no request with the input username is found.
    }

    /**
     * Add a new customer
     * @param {string} _userName Name of the customer to be added
     * @param {string} _customerData Hash of the customer's ID submitted for KYC
     * @return {uint8} 0 indicates failure, 1 indicates success
     */
    function addCustomer(string memory _userName, string memory _customerData) public returns (uint8) {
        require(customers[_userName].bank == address(0), "This customer is already present");

        if (kycRequests[_customerData].isAllowed) {
            customers[_userName].userName = _userName;
            customers[_userName].data_hash = _customerData;
            customers[_userName].bank = msg.sender;
            customers[_userName].upvotes = 0;
            customers[_userName].rating = 0;
            customerNames.push(_userName);
            return 1;
        }else{
            return 0;
        }
    }

    /**
     * Remove customer information
     * @param  {string} _userName Name of the customer
     * @return {uint8} 0 indicates failure, 1 indicates success
     */
    function removeCustomer(string memory _userName) public returns (uint8) {
            for(uint i = 0;i < customerNames.length;i++)
            {
                if(stringsEquals(customerNames[i],_userName))
                {
                    delete customers[_userName];
                    for(uint j = i+1;j < customerNames.length;j++)
                    {
                        customerNames[j-1] = customerNames[j];
                    }
                    return 1;
                }
            }
            return 0;
    }

    /**
     * Edit customer information
     * @param  {public} _userName Name of the customer
     * @param  {public} _password password of the customer
     * @param  {public} _newcustomerData New hash of the updated ID provided by the customer
     * @return {uint8}   0 indicates failure, 1 indicates success
     */
    function modifyCustomer(string memory _userName, string memory _password, string memory _newcustomerData) public returns (uint8) {
        if(stringsEquals(customers[_userName].password, _password)) {
            for (uint j = 0; j < customerDataList.length; j++) {
            if(stringsEquals(customerDataList[j], customers[_userName].data_hash)) {
                for(uint i = 0;i < customerNames.length;i++){
                        if(stringsEquals(customerNames[i],_userName)) {
                            customers[_userName].data_hash = _newcustomerData;
                            delete customerDataList[j];
                            for(uint z = i+1;j < customerDataList.length;z++)
                                {
                                    customerDataList[z-1] = customerDataList[z];
                                }
                            customers[_userName].upvotes = 0;
                            customers[_userName].rating = 0;
                            customers[_userName].bank = msg.sender;
                            return 1;
                        }
                    }
            }
        }
        }else{
            return 0;
        }
    }

    /**
     * View customer information
     * @param  {public} _userName Name of the customer
     * @param  {public} _password password of the customer
     * @return {string} hash of the customer data in form of a string.
     */
    function viewCustomer(string memory _userName, string memory _password) public view returns (string memory) {
        if(stringsEquals(customers[_userName].password, _password)) {
            return customers[_userName].data_hash;
        }
    }

    /**
     * Fetches the KYC requests for a specific bank.
     * @param {address} _ethAddress The ethAddress of the bank
     * @return {array} list of all the requests initiated by the bank which are yet to be validated.
     */
    function getBankRequests(address _ethAddress) public returns (string[] memory) {
        for(uint8 i = 0; i < banks[_ethAddress].kycRequestList.length; i++) {
            list[i]=banks[_ethAddress].kycRequestList[i];
        }
        return list;
    }

    /**
     * Fetch customer rating from the smart contract
     * @param  {public} _userName Name of the customer
     * @return {uint8} rating
     */
    function getCustomerRating(string memory _userName) public returns (uint8) {
        return customers[_userName].rating;
    }

    /**
     * Fetch bank rating from the smart contract
     * @param {address} _ethAddress The ethAddress of the bank
     * @return {uint8} rating
     */
    function getBankRating(address _ethAddress) public returns (uint8) {
        return banks[_ethAddress].bankRating;
    }

    /**
     * Fetch the bank details
     * @param {address} _ethAddress The ethAddress of the bank
     * @return {Bank}  The Bank struct as an object
     */
    function getBankDetails(address _ethAddress) public returns(address, string memory, uint8, uint8, string memory, address[] memory) {
        return (banks[_ethAddress].ethAddress,banks[_ethAddress].bankName,banks[_ethAddress].kycCount,banks[_ethAddress].bankRating,banks[_ethAddress].regNumber,banks[_ethAddress].bankVotedAddress);
    }

    /**
     * Fetch the bank details which made the last changes to the customer data.
     * @param  {public} _userName Name of the customer
     * @return {address} _ethAddress The ethAddress of the bank
     */
    function retrieveHistory(string memory _userName) public returns(address){
        return customers[_userName].bank;
    }

    /**
     * Add a new upvote from a bank
     * @param {public} _userName Name of the customer to be upvoted
     * @return {uint8}   0 indicates failure, 1 indicates success
     */
    function customerUpvote(string memory _userName) public returns (uint8) {

        for(uint j = 0; j < customers[_userName].votedBankAddress.length;j++){
            if(customers[_userName].votedBankAddress[j] == msg.sender) {
                return 0;
            }
        }

        if (customers[_userName].rating > threshold) {
            uint256 index = 0;
            delete banks[msg.sender].kycRequestList[index];
            uint8 i = 0;
            for (uint j = i+1;j < banks[msg.sender].kycRequestList.length;j++)
                {
                    banks[msg.sender].kycRequestList[j-1] = banks[msg.sender].kycRequestList[j];
                }
        }

        for(uint i = 0;i < customerNames.length;i++)
            {
                if(stringsEquals(customerNames[i],_userName))
                {
                    customers[_userName].upvotes + 100 finney;
                    customers[_userName].rating + 100 finney;
                    customers[_userName].votedBankAddress.push(msg.sender);
                    return 1;
                }
            }
    }

    /**
     * Add a new upvote from a bank
     * @param {address} _ethAddress The ethAddress of the bank
     * @return {uint8}   0 indicates failure, 1 indicates success
     */
    function bankUpvote(address _ethAddress) public returns (uint8) {

        for(uint j = 0; j < banks[_ethAddress].bankVotedAddress.length; j++){
            if(banks[_ethAddress].bankVotedAddress[j] == _ethAddress) {
                return 0;
            }
        }

        for(uint i = 0;i < bankAddresses.length;i++)
            {
                if(bankAddresses[i] == _ethAddress)
                {
                    banks[_ethAddress].bankRating + 100 finney;
                    banks[_ethAddress].bankVotedAddress.push(_ethAddress);
                    return 1;
                }
            }
        return 0;
    }

    /**
     * Set a password for customer data
     * @param  {public} _userName Name of the customer
     * @param  {public} _password password of the customer
     * @return {uint8}   0 indicates failure, 1 indicates success
     */
    function setPassword(string memory _userName, string memory _password) public returns (uint8) {

        customers[_userName].password = _password;
        return 1;

    }

// if you are using string, you can use the following function to compare two strings
// function to compare two string value
// This is an internal fucntion to compare string values
// @Params - String a and String b are passed as Parameters
// @return - This function returns true if strings are matched and false if the strings are not matching
    function stringsEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }

    /*
    *   ////////////////
    *   Admin Interface
    *   ///////////////
    */

    /**
     * Add a new bank
     * @param {string} _bankName Name of the bank to be added
     * @param {address} _ethAddress The ethAddress of the bank
     * @param {string} _regNumber The regNumber of the bank
     * @return {uint8}   0 indicates failure, 1 indicates success
     */
    function addBank(string memory _bankName, address _ethAddress, string memory _regNumber) public onlyOwner returns (uint8) {
         for (uint i = 0; i < bankAddresses.length; i++) {
           if(bankAddresses[i] == _ethAddress) {
               revert("Bank already exists");
           }
        }
        banks[_ethAddress].bankName = _bankName;
        banks[_ethAddress].ethAddress = _ethAddress;
        banks[_ethAddress].regNumber = _regNumber;
        banks[_ethAddress].kycCount = 0;
        banks[_ethAddress].bankRating = 0;
        bankAddresses.push(_ethAddress);
        return 1;
    }

    /**
     * Remove a bank
     * @param {address} _ethAddress The ethAddress of the bank
     * @return {uint8}   0 indicates failure, 1 indicates success
     */
    function removeBank(address _ethAddress) public onlyOwner returns (uint8) {
            for(uint i = 0;i < bankAddresses.length;i++)
            {
                if(bankAddresses[i] == _ethAddress)
                {
                    delete banks[_ethAddress];
                    for(uint j = i+1;j < bankAddresses.length;j++)
                    {
                        bankAddresses[j-1] = bankAddresses[j];
                    }
                    return 1;
                }
            }
            return 0;
    }

}

