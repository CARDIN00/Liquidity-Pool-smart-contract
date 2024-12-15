// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleErc20{
    string public tokenName;
    string public tokenSymbol;
    uint8 public descimal;
    uint public totalSuply;

    // mappings
    mapping(address => uint) public Balance;
    mapping(address => mapping (address => uint)) public Allowance;

    // Constructor
    constructor(
        uint _initialSupply,
        string memory _name,
        string memory _symbol,
        uint8 _descimal
    )
    {
        tokenName = _name;
        tokenSymbol =_symbol;
        descimal = _descimal;

        totalSuply = _initialSupply* (10** _descimal);
        Balance[msg.sender]= totalSuply;

    }

    // FUNCTIONS
    function balanceOf( address _user) public view returns(uint){
        return Balance[_user];
    }

    function allowance(address _owner, address _spender) public view returns (uint){
        return Allowance[_owner][_spender];
    }

    function transfer(  address _to, uint amount)public returns (bool){
        require(Balance[msg.sender] >= amount);
        require(_to != address(0) && _to != msg.sender);
        Balance[msg.sender] -= amount;
        Balance[_to] += amount;
        return  true;
    }

    function approve(address spender, uint amount) public returns (bool){
        Allowance[msg.sender][spender] = amount;
        return  true;
    }

    function transferFrom(address sender, address _to, uint amount) public returns (bool){
        require(Balance[sender] >= amount && Allowance[sender][msg.sender] >= amount,"check balance");
        Balance[sender] -= amount;
        Allowance[sender][msg.sender] -=amount;
        Balance[_to] += amount;
        return  true;

    }

    
}
