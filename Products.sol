// This is a simple market place smart contract 
// Features;
// Creator can invoke and revoke users registration
// Product creator must be a registered users
// Registered user only have a max number of products to add
// If products >= , user will have to upgrade account with no limit to number of products a user can add

pragma solidity ^0.5.10;

contract Products{
    uint public userCount;
    uint public productCount;
    address payable onwerContract;
    uint UPGRADE_FEE = 0.5 ether;

    mapping(address => User) public users;
    mapping(uint => Product) public products;
    mapping(uint => address) public userList;
    enum State {Waiting, Open, Closed}
    State public state;

    struct User{
        bool isUser;
        uint id;
        string name;
        uint[] ownedProducts;
        bool level;
    }

    struct Product{
        uint id;
        string name;
        uint price;
        address onwer;
    }

    event userAdded(
        uint id,
        string name,
        address userAddress
    );

    event productAdded(
        uint id,
        string name,
        uint price,
        address ownerAddress
    );
    
    event userUpgraded(
        uint amount,
        address indexed user,
        uint timePaid
    );
    
    modifier checkUserUploads{
        if(!users[msg.sender].level){
            require(users[msg.sender].ownedProducts.length < 5, 'You have uploaded more than required');
        }
        _;
    }
    
    modifier notOwner{
        require(onwerContract != msg.sender, 'Contract creator can not add products.');
        _;
    }    
    
    modifier onlyOwner{
        require(onwerContract == msg.sender, 'You do not have the privledge.');
        _;
    }
    
    modifier checkRegistrationSate(State _state){
        require(state == _state, 'User regitration is over.');
        _;
    }

    constructor(string memory _name) public{
        onwerContract = msg.sender;
        userCount++;

        users[msg.sender] = User(true, userCount, _name, new uint[](0), false);
        userList[userCount] = msg.sender;
        emit userAdded(userCount, _name, msg.sender);
    }

    function userReg(string memory _name) public checkRegistrationSate(State.Open){
        require(!users[msg.sender].isUser, 'You already registered');
        require(bytes(_name).length > 0, 'Invalid name entered');
        
        userCount++;

        users[msg.sender] = User(true, userCount, _name, new uint[](0), false);
        userList[userCount] = msg.sender;
        emit userAdded(userCount, _name, msg.sender);
    }

    function addProduct(string memory _name, uint _price) public checkUserUploads notOwner{
        require(bytes(_name).length > 0, 'Invalid name entered');
        require(_price > 0, 'Invalid string entered');
        require(users[msg.sender].isUser, 'You must register first');

        productCount++;
        
        products[productCount] = Product(productCount, _name, _price, msg.sender);
        users[msg.sender].ownedProducts.push(productCount);
        
        emit productAdded(productCount, _name, _price, msg.sender);
    }

    function viewUserPrducts() external view returns (uint[] memory){
        return users[msg.sender].ownedProducts;
    }
    
    function closeRegistration() public onlyOwner checkRegistrationSate(State.Open){
        require(userCount >= 5, 'User registration is still open');
        
        state = State.Closed;
    }    
    
    function openRegistration() public onlyOwner checkRegistrationSate(State.Waiting){
        require(userCount <= 1 , 'User registration is still open');
        
        state = State.Open;
    }
    
    function upgradeUser() public payable returns (bool){
        require(users[msg.sender].isUser, 'You must register first');
        require(!users[msg.sender].level, 'You must register first');
        require(msg.value >= UPGRADE_FEE, 'Value sent is less than required');
        
        onwerContract.transfer(msg.value);
        
        users[msg.sender].level = true;
        emit userUpgraded(msg.value, msg.sender, now);
    }
}