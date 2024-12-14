// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../simpleErc20.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";





contract LiquidityPool is  Pausable {
    address public Owner;
    uint public depositeFee;
    uint public WithdrawFee;
    uint public poolToken; // total token in the pool
    uint public  poolEther; // total Ether in the pool
    simpleErc20 public token;

    uint public totalEtherFee;
    uint public totalTokenFee;

    uint256 public totalShares; // Total shares in the pool

    // MAPPINGS
    mapping (address => uint) public EtherBalance;
    mapping (address => uint) public tokenBal;
    mapping(address => uint256) public userShares; // Tracks each user's share

    
    constructor(address _token)
    {
        Owner =msg.sender;
        token = simpleErc20(_token);
        depositeFee = 1;
        WithdrawFee =1;
    }

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    // FUNCTIONS

    function pause() external onlyOwner {
    _pause();
    }

    function unpause() external onlyOwner {
    _unpause();
    }

    // functions for the owner
    function getOwnerPoolSummary() external view onlyOwner returns (
    uint256 etherLiquidity,
    uint256 tokenLiquidity,
    uint256 etherFees,
    uint256 tokenFees,
    uint256 totalPoolShares
) {
    etherLiquidity = poolEther;
    tokenLiquidity = poolToken;
    etherFees = totalEtherFee;
    tokenFees = totalTokenFee;
    totalPoolShares = totalShares;
}

    function getUserSharePercentage(address user) public view returns (uint256) {
    if (totalShares == 0) {
        return 0;
    }
    return (userShares[user] * 100) / totalShares;
    }

    //update deposite fee
    function updateDepositFee(uint256 newFee) external onlyOwner {
    require(newFee <= 50, "Fee too high"); // Max 5%
    depositeFee = newFee;
    }

    //update withdrawal fee
    function updateWithdrawFee(uint256 newFee) external onlyOwner {
    require(newFee <= 50, "Fee too high"); // Max 5%
    WithdrawFee = newFee;
    }

    // get the torak amount of ether and tokens in the pool
    function getTotalLiquidity() external view returns (uint256 etherLiquidity, uint256 tokenLiquidity) {
    etherLiquidity = poolEther;
    tokenLiquidity = poolToken;
    }

    // get the ether and token balance of user
    function getUserBalances(address user) external view returns (uint256 etherBalance, uint256 tokenBalance) {
    etherBalance = EtherBalance[user];
    tokenBalance = tokenBal[user];
    }



    // Deposite functions
    function depositeEther()public payable whenNotPaused {
        uint fee = (msg.value * depositeFee) /1000;
        uint amountAferFee = msg.value - fee;
        EtherBalance[msg.sender] += amountAferFee;
        poolEther += amountAferFee;
        totalEtherFee += fee;
    }

    // function to deposite erc20 tokens
    function depositeToken(uint _amount) external  payable whenNotPaused{
        uint fee = (_amount * depositeFee)/1000;
        uint amountAfterFee = _amount - fee;

        // tokens need to expicitly call tje transfer function from erc contract as they are not part of the ether network
        token.transferFrom(msg.sender, address(this), _amount);
        tokenBal[msg.sender] += amountAfterFee;
        totalTokenFee += fee;

        poolToken += amountAfterFee;

         // Update user shares
        updateSharesOnDeposit(amountAfterFee);
    }

    // Withdraw Functions
    //function to withdraw Ether
    function withdrawEther(uint _amount) external{
        uint fee = (_amount * depositeFee) /1000;
        uint amountAfterFee = _amount -fee;
        require(EtherBalance[msg.sender] >= amountAfterFee,"Insufficient Amount");

        EtherBalance[msg.sender] -= amountAfterFee;
        poolEther -= amountAfterFee;
        totalEtherFee += fee;

        // Update user shares
        updateSharesOnWithdrawal(amountAfterFee);

        payable (msg.sender).transfer(amountAfterFee);
    }

    //function to withdraw tokens
    function withdrawToken(uint _amount) external{
        uint fee = (_amount * depositeFee) /1000;
        uint amountAfterFee = _amount -fee;

        require(tokenBal[msg.sender] >= amountAfterFee);
        tokenBal[msg.sender] -= amountAfterFee;
        poolToken -= amountAfterFee;
        totalTokenFee += fee;

        payable (msg.sender).transfer(_amount);
        
    }

    //SHare in pool
    function userEtherShare(address _user) external view returns (uint){
        if(poolEther == 0) return  0;
        return (tokenBal[_user] *100) / poolEther;// percentage of the share
    }

    function userTokenShare(address _user) external view returns (uint){
        if (poolToken == 0) return 0;
        return (EtherBalance[_user] *100)/ poolToken;
    }

    //  Implement a mechanism to allow users to withdraw their liquidity from the pool.
    // Wtihdraw the percentage of :
    // Ether
    function withdrawEtherLiquidity(uint _sharepercentage) external{
        require(_sharepercentage > 0 && _sharepercentage< 100,"invalid");

        uint etherToWithdraw = (poolEther * _sharepercentage)/100;
        require(EtherBalance[msg.sender] >= etherToWithdraw);

        EtherBalance[msg.sender] -= etherToWithdraw;
        poolEther -= etherToWithdraw;

        payable (msg.sender).transfer(etherToWithdraw);
    }

    // tokens
    function withdrawTokenLiquidity(uint _sharePercentage) external{
        require(_sharePercentage > 0 && _sharePercentage <100);

        uint tokenToWithdraw = (poolToken * _sharePercentage) /100;
        require(tokenBal[msg.sender] >= tokenToWithdraw);
        tokenBal[msg.sender] -= tokenToWithdraw;

        poolToken -= tokenToWithdraw;
        payable (msg.sender).transfer(tokenToWithdraw);
    }

    function WithdraEtherFee() external onlyOwner{
        uint fees = totalEtherFee;
        require(fees> 0,"no withdrawal available");

        totalEtherFee =0;
        payable (Owner).transfer(fees);
    }

    function WithdrawTokenFee() external onlyOwner{
        uint fee = totalTokenFee;
        require(fee > 0,"no withdrawal available");

        totalTokenFee =0;
        token.transfer( Owner, fee);
    }

    function updateSharesOnDeposit(uint256 depositValue) internal {
    if (totalShares == 0) {
        // First depositor gets 100% of the shares
        userShares[msg.sender] += depositValue;
        totalShares += depositValue;
    } else {
        // Calculate shares based on the depositor's contribution
        uint256 newShares = (depositValue * totalShares) / (poolEther + poolToken);
        userShares[msg.sender] += newShares;
        totalShares += newShares;
    }
    }

    function updateSharesOnWithdrawal(uint256 withdrawalValue) internal {
    uint256 userShare = userShares[msg.sender];
    require(userShare > 0, "No shares to withdraw");

    // Calculate the shares to deduct
    uint256 sharesToDeduct = (withdrawalValue * totalShares) / (poolEther + poolToken);
    require(userShare >= sharesToDeduct, "Insufficient shares");

    userShares[msg.sender] -= sharesToDeduct;
    totalShares -= sharesToDeduct;
    }


}