pragma solidity >=0.4.21 <0.6.0;

contract Lotto{
    uint total_ETH;
    CloudFunding[] cloudFundings;
    event ev_createFunding(uint _id);
    event ev_insertETH(address payable _user, uint _nowAmount, uint _totalAmount);
    event ev_endConfirm(bool _result);
    function createFunding() external {
        uint id = cloudFundings.push(new CloudFunding(msg.sender)) - 1;
        emit ev_createFunding(id);
    }
    function insertETH(uint _id) external payable{
        uint _amount = msg.value;
        cloudFundings[_id].insertETH(msg.sender, _amount);
        emit ev_insertETH(msg.sender, _amount, 0);
    }
    function endConfirm(uint _id) external {
        cloudFundings[_id].Userconfirm(msg.sender);
        emit ev_endConfirm(true);
    }
    function withdrawFunding(uint _id) external payable{
        address payable user;
        uint amount;
        (user, amount) = cloudFundings[_id].withdrawETH();
        transfer(msg.sender, user, amount);
    }
}

contract CloudFunding {
    uint128 total_amount;
    uint64 openDay;
    bool isClosed;
    address payable owner;
    mapping(address => uint256) balanceOf;
    mapping(address => bool) confirm;
    address payable[] participants;
    constructor(address payable _user) public {
        owner = _user;
        total_amount = 0;
        openDay = uint64(now);
        isClosed = false;
    }
    modifier md_isClosed() {
        require(!isClosed, "종료된 펀딩");
        _;
    }
    function _alreadyUser(address payable _user) private view returns(bool){
        for(uint i = 0 ; i < participants.length ; i++) {
            if(participants[i] == _user) {
                return true;
            }
        }
        return false;
    }
    function _agreeWithdraw() private view returns(bool) {
        for(uint i = 0 ; i < participants.length ; i++) {
            if(!confirm[participants[i]]) return false;
        }
        return true;
    }
    function insertETH(address payable _user, uint _amount) public md_isClosed(){
        if(!_alreadyUser(_user)) participants.push(_user);
        total_amount = uint128(total_amount + _amount);
        balanceOf[_user] = balanceOf[_user] + _amount;
        confirm[_user] = false;
    }
    function Userconfirm(address payable _user) public {
        confirm[_user] = true;
    }
    function withdrawETH() public md_isClosed() returns(address payable _user, uint _amount){
        require(_agreeWithdraw(),"");
        for(uint i = 0 ; i < participants.length ; i++) {
            require(total_amount >= 0, "");
        }
        isClosed = true;
        return (owner, total_amount);
    }
}