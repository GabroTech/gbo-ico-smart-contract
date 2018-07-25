pragma solidity ^0.4.15;

// ================= Ownable Contract start =============================
/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents functions from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public  onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
// ================= Ownable Contract end ===============================

// ================= Safemath Contract start ============================
/* taking ideas from FirstBlood token */
contract SafeMath {

  function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x + y;
    assert((z >= x) && (z >= y));
    return z;
  }

  function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
    assert(x >= y);
    uint256 z = x - y;
    return z;
  }

  function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x * y;
    assert((x == 0)||(z/x == y));
    return z;
  }
}
// ================= Safemath Contract end ==============================

// ================= ERC20 Token Contract start =========================
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public  constant returns (uint);
  function allowance(address owner, address spender) public  constant returns (uint);
  function transfer(address to, uint value) public  returns (bool ok);
  function transferFrom(address from, address to, uint value) public  returns (bool ok);
  function approve(address spender, uint value) public  returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
// ================= ERC20 Token Contract end ===========================

// ================= Standard Token Contract start ======================
contract StandardToken is ERC20, SafeMath {
  /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) public  onlyPayloadSize(2 * 32)  returns (bool success){
    balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public  onlyPayloadSize(3 * 32) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSubtract(balances[_from], _value);
    allowed[_from][msg.sender] = safeSubtract(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public  constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public  returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public  constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}
// ================= Standard Token Contract end ========================

// ================= Pausable Token Contract start ======================
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
  * @dev modifier to allow actions only when the contract IS paused
  */
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  /**
  * @dev modifier to allow actions only when the contract IS NOT paused
  */
  modifier whenPaused {
    require (paused) ;
    _;
  }

  /**
  * @dev called by the owner to pause, triggers stopped state
  */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
  * @dev called by the owner to unpause, returns to normal state
  */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}
// ================= Pausable Token Contract end ========================

// ================= IcoToken  start =======================
contract IcoToken is SafeMath, StandardToken, Pausable {
  string public name;
  string public symbol;
  uint256 public decimals;
  string public version;
  address public icoContract;

  constructor(
    string _name,
    string _symbol,
    uint256 _decimals,
    string _version
  ) public
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    version = _version;
  }

  function transfer(address _to, uint _value) public  whenNotPaused returns (bool success) {
    return super.transfer(_to,_value);
  }

  function approve(address _spender, uint _value) public  whenNotPaused returns (bool success) {
    return super.approve(_spender,_value);
  }

  function balanceOf(address _owner) public  constant returns (uint balance) {
    return super.balanceOf(_owner);
  }

  function setIcoContract(address _icoContract) public onlyOwner {
    if (_icoContract != address(0)) {
      icoContract = _icoContract;
    }
  }

  function sell(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
      assert(_value > 0);
      require(msg.sender == icoContract);

      balances[_recipient] += _value;
      totalSupply += _value;

      emit Transfer(0x0, owner, _value);
      emit Transfer(owner, _recipient, _value);
      return true;
  }

}

// ================= Ico Token Contract end =======================

// ================= Actual Sale Contract Start ====================
contract IcoContract is SafeMath, Pausable {
  IcoToken public ico;

  uint256 public tokenCreationCap;
  uint256 public totalSupply;

  address public ethFundDeposit;
  address public icoAddress;

  uint256 public fundingStartTime;
  uint256 public fundingEndTime;
  uint256 public minContribution;

  bool public isFinalized;
  uint256 public tokenExchangeRate;

  event LogCreateICO(address from, address to, uint256 val);

  function CreateICO(address to, uint256 val) internal returns (bool success) {
    emit LogCreateICO(0x0, to, val);
    return ico.sell(to, val);
  }

  constructor(
    address _ethFundDeposit,
    address _icoAddress,
    uint256 _tokenCreationCap,
    uint256 _tokenExchangeRate,
    uint256 _fundingStartTime,
    uint256 _fundingEndTime,
    uint256 _minContribution
  ) public
  {
    ethFundDeposit = _ethFundDeposit;
    icoAddress = _icoAddress;
    tokenCreationCap = _tokenCreationCap;
    tokenExchangeRate = _tokenExchangeRate;
    fundingStartTime = _fundingStartTime;
    minContribution = _minContribution;
    fundingEndTime = _fundingEndTime;
    ico = IcoToken(icoAddress);
    isFinalized = false;
  }

  function () public payable {
    createTokens(msg.sender, msg.value);
  }

  /// @dev Accepts ether and creates new ICO tokens.
  function createTokens(address _beneficiary, uint256 _value) internal whenNotPaused {
    require (tokenCreationCap > totalSupply);
    require (now >= fundingStartTime);
    require (now <= fundingEndTime);
    require (_value >= minContribution);
    require (!isFinalized);
    uint256 tokens;
    if (_beneficiary == ethFundDeposit) {
      tokens = safeMult(_value, 30000000);
    } else {
      if (now <= 1533312000){ // 08/03/2018 @ 4:00pm (UTC) = HKT 2018/8/4 0:00:00
        if ( _value < 5000000000000000000) {
            // value < 5 ETH, 100%, 1 ETH = 5000 GBO
          tokens = safeMult(_value, 5000);
        } else if ( _value < 10000000000000000000){
          // value < 10 ETH, 120%, 1 ETH = 6000 GBO
          tokens = safeMult(_value, 6000);
        } else if ( _value < 30000000000000000000){
          // value < 30 ETH, 125%, 1 ETH = 6250 GBO
          tokens = safeMult(_value, 6250);
        } else {
          // value >=30 ETH, 130%, 1 ETH = 6500 GBO
          tokens = safeMult(_value, 6500);
        }
      } else if ( now <= 1535731200 ){ //  08/31/2018 @ 4:00pm (UTC) = HKT 2018/9/1 0:00:00
        if ( _value < 5000000000000000000) {
            // value < 5 ETH, 100%, 1 ETH = 5000 GBO
          tokens = safeMult(_value, 5000);
        } else if ( _value < 10000000000000000000){
          // value < 10 ETH, 110%, 1 ETH = 5500 GBO
          tokens = safeMult(_value, 5500);
        } else if ( _value < 30000000000000000000){
          // value < 30 ETH, 115%, 1 ETH = 5750 GBO
          tokens = safeMult(_value, 5750);
        } else {
          // value >=30 ETH, 120%, 1 ETH = 6000 GBO
          tokens = safeMult(_value, 6000);
        }
      } else if ( now <= 1536336000 ){ //  09/07/2018 @ 4:00pm (UTC)
        if ( _value < 5000000000000000000) {
            // value < 5 ETH, 100%, 1 ETH = 5000 GBO
          tokens = safeMult(_value, 5000);
        } else if ( _value < 10000000000000000000){
          // value < 10 ETH, 109%, 1 ETH = 5450 GBO
          tokens = safeMult(_value, 5450);
        } else if ( _value < 30000000000000000000){
          // value < 30 ETH, 114%, 1 ETH = 5700 GBO
          tokens = safeMult(_value, 5700);
        } else {
          // value >=30 ETH, 119%, 1 ETH = 5950 GBO
          tokens = safeMult(_value, 5950);
        }
      } else if ( now <= 1536940800 ){ //  09/14/2018 @ 4:00pm (UTC)
        if ( _value < 5000000000000000000) {
            // value < 5 ETH, 100%, 1 ETH = 5000 GBO
          tokens = safeMult(_value, 5000);
        } else if ( _value < 10000000000000000000){
          // value < 10 ETH, 108%, 1 ETH = 5400 GBO
          tokens = safeMult(_value, 5400);
        } else if ( _value < 30000000000000000000){
          // value < 30 ETH, 113%, 1 ETH = 5650 GBO
          tokens = safeMult(_value, 5650);
        } else {
          // value >=30 ETH, 118%, 1 ETH = 5900 GBO
          tokens = safeMult(_value, 5900);
        }
      } else if ( now <= 1537545600 ){ //  09/21/2018 @ 4:00pm (UTC)
        if ( _value < 5000000000000000000) {
            // value < 5 ETH, 100%, 1 ETH = 5000 GBO
          tokens = safeMult(_value, 5000);
        } else if ( _value < 10000000000000000000){
          // value < 10 ETH, 107%, 1 ETH = 5350 GBO
          tokens = safeMult(_value, 5350);
        } else if ( _value < 30000000000000000000){
          // value < 30 ETH, 112%, 1 ETH = 5600 GBO
          tokens = safeMult(_value, 5600);
        } else {
          // value >=30 ETH, 117%, 1 ETH = 5850 GBO
          tokens = safeMult(_value, 5850);
        }
      } else if ( now <= 1538150400 ){ //  09/28/2018 @ 4:00pm (UTC)
        if ( _value < 5000000000000000000) {
            // value < 5 ETH, 100%, 1 ETH = 5000 GBO
          tokens = safeMult(_value, 5000);
        } else if ( _value < 10000000000000000000){
          // value < 10 ETH, 106%, 1 ETH = 5300 GBO
          tokens = safeMult(_value, 5300);
        } else if ( _value < 30000000000000000000){
          // value < 30 ETH, 111%, 1 ETH = 5550 GBO
          tokens = safeMult(_value, 5550);
        } else {
          // value >=30 ETH, 116%, 1 ETH = 5800 GBO
          tokens = safeMult(_value, 5800);
        }
      } else {
          tokens = safeMult(_value, 5000);
      }
    }
    uint256 checkedSupply = safeAdd(totalSupply, tokens);

    if (tokenCreationCap < checkedSupply) {
      uint256 tokensToAllocate = safeSubtract(tokenCreationCap, totalSupply);
      uint256 tokensToRefund   = safeSubtract(tokens, tokensToAllocate);
      totalSupply = tokenCreationCap;
      uint256 etherToRefund = tokensToRefund / tokenExchangeRate;

      require(CreateICO(_beneficiary, tokensToAllocate));
      msg.sender.transfer(etherToRefund);
      ethFundDeposit.transfer(address(this).balance);
      return;
    }

    totalSupply = checkedSupply;

    require(CreateICO(_beneficiary, tokens));
    ethFundDeposit.transfer(address(this).balance);
  }

  /// @dev Ends the funding period and sends the ETH home
  function finalize() external onlyOwner {
    require (!isFinalized);
    // move to operational
    isFinalized = true;
    ethFundDeposit.transfer(address(this).balance);
  }
}
