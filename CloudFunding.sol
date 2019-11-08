pragma solidity >=0.4.21 <0.6.0;
contract CloudFunding {
    uint128 public total_amount;
    uint64 public openDay;
    bool public isClosed;
    address payable owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public confirm;
    address payable[] public participants;
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
    function showInfo() public view returns(uint, uint, bool, address payable, address payable[] memory) {
        return (
            total_amount,
            openDay,
            isClosed,
            owner,
            participants
        );
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
        require(_alreadyUser(_user),"펀딩에 참여자만 승인할 수 있습니다.");
        require(confirm[_user] == false,"이미 승인하셧습니다.");
        confirm[_user] = true;
    }
    function withdrawETH(address payable _user) public md_isClosed() returns(address payable, uint){
        require(_agreeWithdraw(),"누군가가 허락하지 않습니다.");
        require(owner == _user,"이펀딩의 주인공만 철회신청 할 수 있습니다.");
        uint amount = total_amount;
        total_amount = 0;
        isClosed = true;
        return (owner, amount);
    }
}