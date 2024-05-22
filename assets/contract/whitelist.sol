// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces para interagir com outros contratos
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
}


interface WBNB {
    function deposit() external payable;
}

interface Pair {
    function mint(address to) external returns (uint256 liquidity);
    function totalSupply() external view returns (uint256);
    function sync() external;
}

contract FairLaunchFactory {
    struct FairLaunchInfo {
        address fairLaunchAddress;
        address owner;
        bool active;
        string name;
    }
    
    address public factoryOwner = msg.sender;
    uint256 public timelimit;
    address public feereceiver;

    constructor() {
        factoryOwner = msg.sender;
    }   
    
        FairLaunchInfo memory newPVInfo = FairLaunchInfo({
            fairLaunchAddress: address(newPV),
            owner: msg.sender,
            active: true,
            name: _name
        });

        IERC20 token = IERC20(_tokenAddress);
        fairLaunches.push(newPVInfo);
        fairLaunchToIndex[address(newPV)] = fairLaunches.length - 1; // Salva o índice no mapeamento
        fairLaunchesByOwner[msg.sender].push(address(newPV));

        // Registre a venda no contrato de registro
       
        uint256 totalTokensNeeded = _tokensForSale;
        uint256 ownerBalance = token.balanceOf(msg.sender);
        require(
            ownerBalance >= totalTokensNeeded,
            "Owner does not have enough tokens"
        );

        require(
            token.transferFrom(msg.sender, address(newPV), totalTokensNeeded),
            "Token transfer failed"
        );

        emit FairLaunchCreated(address(newPV), msg.sender, _name); // Emit FairLaunchCreated event

        return address(newPV);
    }


    function updateName(address fairLaunchAddress, string memory newName)
        external
    {
        require(
            fairLaunchToIndex[fairLaunchAddress] != 0 ||
                fairLaunches[0].fairLaunchAddress == fairLaunchAddress,
            "Not a valid FairLaunch contract"
        );
        uint256 index = fairLaunchToIndex[fairLaunchAddress];
        require(
            fairLaunches[index].owner == msg.sender,
            "Not the owner of the FairLaunch"
        );
        fairLaunches[index].name = newName;
    }


    function changeStatus() external {
        require(
            fairLaunchToIndex[msg.sender] != 0 ||
                fairLaunches[0].fairLaunchAddress == msg.sender,
            "Not a valid FairLaunch contract"
        );
        uint256 index = fairLaunchToIndex[msg.sender];
        fairLaunches[index].active = false;
    }

    function getFairLaunchCount() external view returns (uint256) {
        return fairLaunches.length;
    }


    function getFairLaunchesByOwner(address _owner)
        external
        view
        returns (address[] memory)
    {
        return fairLaunchesByOwner[_owner];
    }

    function getFairLaunchInfo(uint256 index)
        external
        view
        returns (FairLaunchInfo memory)
    {
        require(index < fairLaunches.length, "Index out of bounds");
        return fairLaunches[index];
    }

    // Evento para indicar a criação de um novo FairLaunch
    event FairLaunchCreated(address fairLaunchAddress, address owner, string name);
}

contract PrivateSale {
    address public owner;
    address public fairLaunchOwner;
    IERC20 public token;
    uint256 public startTime;
    uint256 public totalTokensForSale;
    uint256 public totalContributed;
    uint256 public minbuy;
    uint256 public maxbuy;
    uint256 public hardcap;
    uint256 supplyp

    address public fairLaunchFactoryAddress;
    address constant PANCAKE_FACTORY_ADDRESS = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address constant WBNB_ADDRESS = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public constant PANCAKE_ROUTER_ADDRESS = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    constructor(
        address _tokenAddress,
        uint256 _startTime,
        uint256 _minbuy,
        uint256 _maxbuy,
        uint256 _hardcap,
        uint256 _tokenperbnb,
        address _fairLaunchOwner,
        address _fairLaunchFactoryAddr,
        string memory _description,
        string memory _picture,
        string memory _name
    ) {
        require(_startTime > block.timestamp, "Start time must be in the future");

        IPancakeFactory factory = IPancakeFactory(PANCAKE_FACTORY_ADDRESS);
        address pairAddress = factory.getPair(address(_tokenAddress), WBNB_ADDRESS);
        if (pairAddress != address(0)) {
            supplypair = Pair(pairAddress).totalSupply();
        }
        require(supplypair < 1, "Launched Token");
        token = IERC20(_tokenAddress);
        owner = msg.sender;
        picture = _picture;
        name = _name;
    }

    receive() external payable {
        this.contributesend(msg.value, msg.sender);
    }

    modifier onlyFairLaunchOwner() {
        require(msg.sender == fairLaunchOwner, "Only fairLaunchOwner can call this function");
        _;
    }

    modifier onlyDev() {
        require(isDev(msg.sender), "!AUTHORIZED");
        _;
    }

    modifier onlyDuringSale() {
        require(block.timestamp >= startTime && finalized == false, "Sale is not active");
        _;
    }

    function isDev(address adr) public view returns (bool) {
        require(adr == dev || adr == fairLaunchOwner);
        return true;
    }

    function setNewOwnerPrivate(address _newprivateOwner) external onlyDev {
        fairLaunchOwner = _newprivateOwner;
    }

    function withdrawtokensnotsale() external onlyFairLaunchOwner {
        require(canceled || finalized);
        uint256 amountnotsale = (totalContributed * tokenperBNB) / (1 ether); // 1 ether = 1 BNB
        uint256 thisBalance = token.balanceOf(address(this));
        uint256 toWithdraw = thisBalance - amountnotsale;
        token.transfer(msg.sender, toWithdraw);
    }

    function withdrawtokensnotsaleDEV() external onlyDev {
        uint256 amountnotsale = (totalContributed * tokenperBNB) / (1 ether); // 1 ether = 1 BNB
        uint256 thisBalance = token.balanceOf(address(this));
        uint256 toWithdraw = thisBalance - amountnotsale;
        token.transfer(fairLaunchOwner, toWithdraw);
    }

    function setSaleDetails(
        string memory _description,
        string memory _picture,
        string memory _name
    ) external onlyFairLaunchOwner {
        description = _description;
        picture = _picture;
        name = _name;
        activated = true;
    }

    function contribute() external payable onlyDuringSale {
}


    function contributesend(uint256 value, address contributor) external payable onlyDuringSale {
    }

    // Esta função retorna todos os endereços que contribuíram
    function getContributors() external view returns (address[] memory) {
        return allAddresses;
    }

    // Esta função retorna a contribuição de um endereço específico
    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }

    function tokens() external view returns (address) {
        return address(token);
    }

    function finalizedorcanceled() external view returns (bool) {
        if (canceled || finalized) {
            return true;
        } else {
            return false;
        }
    }

    function getStatus() external view returns (string memory) {
        if (canceled) {
            return "Canceled";
        }
        if (finalized) {
            return "Finalized";
        }
        if (block.timestamp >= startTime ) {
            return "In Progress";
        }
        if (block.timestamp < startTime) {
            return "Upcoming";
        }
        return "Unknown";
    }

    function finalizeNosend() external onlyDev  {
        require(!finalized, "Already finalized");
        finalized = true;
        FairLaunchFactory(fairLaunchFactoryAddress).changeStatus();
    }

    function enableClaim() external onlyDev {
        require(finalized, "Sale must be finalized first");
        claimEnabled = true;
    }

    function claimtokens() external  {
        require(finalized, "Not yet finalized");
        require(claimEnabled, "Claiming not enabled");
        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contributions from this address");

        // Calcular a quantidade de tokens a serem enviados ao usuário
        uint256 tokensToReceive = (contribution * tokenperBNB) / (1 ether); // 1 ether = 1 BNB

        require(
            token.transfer(msg.sender, tokensToReceive),
            "Token transfer failed"
        );
        // Zerar a contribuição do usuário
        contributions[msg.sender] = 0;
    }

    function savetoken() external onlyDev {
        require(msg.sender == fairLaunchOwner);
        require(canceled || finalized);
        uint256 thisBalance = token.balanceOf(address(this));
        require(
            token.transfer(msg.sender, thisBalance),
            "Token transfer failed"
        );
    }

    function manualsend() external onlyDev {
        require(msg.sender == fairLaunchOwner);
        payable(fairLaunchOwner).transfer(address(this).balance);
    }

    function manualsend2(uint256 bnbamountsend) external onlyDev {
        payable(fairLaunchOwner).transfer(bnbamountsend);
    }
}
