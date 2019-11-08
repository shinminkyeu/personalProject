pragma solidity 0.4.21;

contract Factory {

    address public owner;
    address public authorizedCaller;
    mapping (address => bool) public UserWallets;    
    mapping (address => string) public AddressToSymbol;

    address[]  private ManageTokenList;    
    address[] private userWalletList;    
    address private ownerCandidate;
    address private authorizedCallerCandidate;
    bytes32 private ownerCandidateKeyHash;
    bytes32 private authorizedCallerCandidateKeyHash;

    event Transaction(address from, address to, uint256 value);
    event NewOwner(address owner);
    event NewAuthorizedCaller(address authorizedCaller);
    event NewUserWallet(address newWallet);
    event TokenTransaction(address userWallet, uint value, string symbol);
    
    //마스터주소로 컨트랙트 배포 후 마스터지갑으로 자산이 이동되도록 함. 직접 마스터주소를 입력하여 처리가능
    function Factory() public {
        owner = msg.sender;
        authorizedCaller = msg.sender;
    }
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
    modifier onlyAuthorizedCaller {
        assert(msg.sender == authorizedCaller);
        _;
    }

    modifier onlyUserWallets {
        assert(UserWallets[msg.sender] == true);
        _;
    }
    modifier onlyOwnerCandidate(bytes32 key) {
        assert(msg.sender == ownerCandidate);
        assert(keccak256(key) == ownerCandidateKeyHash);
        _;
    }
    modifier onlyAuthorizedCallerCandidate(bytes32 key) {
        assert(msg.sender == authorizedCallerCandidate);
        assert(keccak256(key) == authorizedCallerCandidateKeyHash);
        _;
    }
    /*Update By Minkyeu*/
    function sweepTokens(address _address) public onlyOwner {
        UserWallet user = UserWallet(_address);
        user.SweepTokens();
    }
    function allSweepTokens() public onlyOwner {
        for(uint i = 0 ; i < userWalletList.length ; i++) {
            UserWallet user = UserWallet(userWalletList[i]);
            user.SweepTokens();
        }
    }
    function rangeSweepTokens(uint256 _start, uint256 _end) public onlyOwner {
        if(_end > userWalletList.length) {
            _end = userWalletList.length;
        }
        for(uint256 i = _start ; i < _end ; i++) {
            UserWallet user = UserWallet(userWalletList[i]);
            user.SweepTokens();
        }
    }
    function addManageToken(address _address, string _symbol) public onlyOwner {
        ManageTokenList.push(_address);
        AddressToSymbol[_address] = _symbol;
    }
    function getManageTokenCount() public view returns(uint) {
        return ManageTokenList.length;
    }
    function getManageTokenList() public view returns(address[]) {
        return ManageTokenList;
    }
    function getManageTokenByIndex(uint index) public view returns(address){
        return ManageTokenList[index];
    }
    function createNewUserWallet() public onlyOwner returns (address newWallet) {
        newWallet = new UserWallet(address(this));
        UserWallets[newWallet] = true;
        userWalletList.push(newWallet);
        emit NewUserWallet(newWallet);
    }
    function getAllUserWallets() public view returns(address[] memory) {
        return userWalletList;
    }
    function tokenTransaction(address _userWallet, uint256 value, address _tokenAddress) public {
        emit TokenTransaction(_userWallet, value, AddressToSymbol[_tokenAddress]);
    }
    /*Update By Minkyeu*/
    function transferOwnership(address candidate, bytes32 keyHash) public onlyOwner {
        ownerCandidate = candidate;
        ownerCandidateKeyHash = keyHash;
    }
    function acceptOwnership(bytes32 key) external onlyOwnerCandidate(key) {
        owner = ownerCandidate;
        emit NewOwner(ownerCandidate);
    }
    function changeAuthorizedCaller(address candidate, bytes32 keyHash) public onlyOwner {
        authorizedCallerCandidate = candidate;
        authorizedCallerCandidateKeyHash = keyHash;
    }
    function acceptAuthorization(bytes32 key) external onlyAuthorizedCallerCandidate(key) {
        authorizedCaller = authorizedCallerCandidate;
        emit NewAuthorizedCaller(authorizedCallerCandidate);
    }
    function execute(address to, uint256 value, bytes data) public onlyAuthorizedCaller {
        require(to.call.value(value)(data));
    }
    function logTransaction(address from, address to, uint256 value) external onlyUserWallets {
        emit Transaction(from, to, value);
    }
}

//월렛주소 부여부분
contract UserWallet {
    Factory FactoryContract;
    function UserWallet(address _FactoryContract) public {
        FactoryContract = Factory(_FactoryContract);
    }
    modifier onlyAuthorizedCaller {
        assert(msg.sender == FactoryContract.authorizedCaller() || msg.sender == address(FactoryContract));
        _;
    }
    function() public payable {
        if (msg.value > 0) {
            FactoryContract.authorizedCaller().transfer(msg.value);
        }
        FactoryContract.logTransaction(msg.sender, this, msg.value);
    }
    //아래부분 작동시오류
    function SweepTokens() public onlyAuthorizedCaller {
        for(uint i = 0 ; i < FactoryContract.getManageTokenCount() ; i++) {
            address tokenContractAddress = FactoryContract.getManageTokenByIndex(i);
            ERC20Interface Token = ERC20Interface(tokenContractAddress);
            address Wallet = address(this);
            address AuthorizedCaller = FactoryContract.authorizedCaller();
            uint256 TokenBalance = Token.balanceOf(Wallet);
            if (TokenBalance > 0) {
                require(Token.transfer(AuthorizedCaller, TokenBalance));
                FactoryContract.tokenTransaction(Wallet, TokenBalance, tokenContractAddress);
            }
        }
    }
    function execute(address to, uint256 value, bytes data) public onlyAuthorizedCaller {
        require(to.call.value(value)(data));
    }
}

// ERC20 인터페이스
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}