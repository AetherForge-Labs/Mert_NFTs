// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title MegaProtocol
 * @dev A monolithic contract combining DEX, NFT, Lending, DAO, Payments, and Analytics features.
 * This is an artificially large contract for testing purposes.
 */
contract MegaProtocol {
    // === TOKEN SECTION ===
    string public name = "MegaToken";
    string public symbol = "MEGA";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(uint256 amount) public {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // === NFT SECTION ===
    struct NFT {
        string name;
        string uri;
        address owner;
        uint256 creationTime;
        uint256 lastTransferTime;
        bool isLocked;
        uint256 royaltyPercentage;
        address[] previousOwners;
        string[] tags;
        uint256[] attributes;
    }

    NFT[] public nfts;
    mapping(uint256 => address) public nftApprovals;
    mapping(uint256 => mapping(address => bool)) public nftOperators;
    mapping(uint256 => uint256) public nftPrices;
    mapping(uint256 => bool) public nftOnSale;

    event NFTMinted(uint256 indexed id, address indexed owner);
    event NFTTransferred(
        uint256 indexed id,
        address indexed from,
        address indexed to
    );
    event NFTSold(
        uint256 indexed id,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event NFTPriceUpdated(uint256 indexed id, uint256 newPrice);
    event NFTApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event NFTAttributeUpdated(
        uint256 indexed id,
        uint256 attributeId,
        uint256 newValue
    );

    function mintNFT(string memory name_, string memory uri) public {
        address[] memory emptyArray;
        string[] memory emptyTags;
        uint256[] memory emptyAttributes;
        nfts.push(
            NFT(
                name_,
                uri,
                msg.sender,
                block.timestamp,
                block.timestamp,
                false,
                0,
                emptyArray,
                emptyTags,
                emptyAttributes
            )
        );
        emit NFTMinted(nfts.length - 1, msg.sender);
    }

    function mintNFTWithAttributes(
        string memory name_,
        string memory uri,
        string[] memory tags,
        uint256[] memory attributes
    ) public {
        address[] memory emptyArray;
        nfts.push(
            NFT(
                name_,
                uri,
                msg.sender,
                block.timestamp,
                block.timestamp,
                false,
                0,
                emptyArray,
                tags,
                attributes
            )
        );
        emit NFTMinted(nfts.length - 1, msg.sender);
    }

    function transferNFT(uint256 id, address to) public {
        require(
            nfts[id].owner == msg.sender ||
                nftApprovals[id] == msg.sender ||
                nftOperators[id][msg.sender],
            "Not owner or approved"
        );
        require(!nfts[id].isLocked, "NFT is locked");
        address from = nfts[id].owner;
        nfts[id].owner = to;
        nfts[id].lastTransferTime = block.timestamp;
        nfts[id].previousOwners.push(from);
        emit NFTTransferred(id, from, to);
    }

    function approveNFT(uint256 id, address to) public {
        require(nfts[id].owner == msg.sender, "Not owner");
        nftApprovals[id] = to;
    }

    function setApprovalForAll(address operator, bool approved) public {
        for (uint256 i = 0; i < nfts.length; i++) {
            nftOperators[i][operator] = approved;
        }
        emit NFTApprovalForAll(msg.sender, operator, approved);
    }

    function setNFTPrice(uint256 id, uint256 price) public {
        require(nfts[id].owner == msg.sender, "Not owner");
        nftPrices[id] = price;
        nftOnSale[id] = true;
        emit NFTPriceUpdated(id, price);
    }

    function buyNFT(uint256 id) public payable {
        require(nftOnSale[id], "NFT not for sale");
        require(msg.value >= nftPrices[id], "Insufficient payment");
        address seller = nfts[id].owner;
        uint256 royalty = (nftPrices[id] * nfts[id].royaltyPercentage) / 100;
        uint256 sellerAmount = nftPrices[id] - royalty;

        nfts[id].owner = msg.sender;
        nfts[id].lastTransferTime = block.timestamp;
        nfts[id].previousOwners.push(seller);
        nftOnSale[id] = false;

        payable(seller).transfer(sellerAmount);
        if (royalty > 0) {
            // In a real contract, royalty would go to the creator
            payable(address(this)).transfer(royalty);
        }

        emit NFTSold(id, seller, msg.sender, nftPrices[id]);
    }

    function lockNFT(uint256 id) public {
        require(nfts[id].owner == msg.sender, "Not owner");
        nfts[id].isLocked = true;
    }

    function unlockNFT(uint256 id) public {
        require(nfts[id].owner == msg.sender, "Not owner");
        nfts[id].isLocked = false;
    }

    function setRoyaltyPercentage(uint256 id, uint256 percentage) public {
        require(nfts[id].owner == msg.sender, "Not owner");
        require(percentage <= 100, "Invalid percentage");
        nfts[id].royaltyPercentage = percentage;
    }

    function updateNFTAttribute(
        uint256 id,
        uint256 attributeId,
        uint256 value
    ) public {
        require(nfts[id].owner == msg.sender, "Not owner");
        if (attributeId >= nfts[id].attributes.length) {
            // Extend the array if needed
            uint256[] memory newAttributes = new uint256[](attributeId + 1);
            for (uint256 i = 0; i < nfts[id].attributes.length; i++) {
                newAttributes[i] = nfts[id].attributes[i];
            }
            nfts[id].attributes = newAttributes;
        }
        nfts[id].attributes[attributeId] = value;
        emit NFTAttributeUpdated(id, attributeId, value);
    }

    function addNFTTag(uint256 id, string memory tag) public {
        require(nfts[id].owner == msg.sender, "Not owner");
        string[] memory newTags = new string[](nfts[id].tags.length + 1);
        for (uint256 i = 0; i < nfts[id].tags.length; i++) {
            newTags[i] = nfts[id].tags[i];
        }
        newTags[nfts[id].tags.length] = tag;
        nfts[id].tags = newTags;
    }

    // === DAO SECTION ===
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 startTime;
        uint256 endTime;
        address proposer;
        uint256 requiredVotes;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) votingPower;
        string[] options;
        uint256[] optionVotes;
        bool isActive;
        uint256 executionDelay;
        uint256 minVotingPower;
        address[] voters;
        uint256 totalVotingPower;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint256 => bool)) public voted;
    mapping(address => uint256) public votingPower;
    mapping(address => uint256) public proposalCount;
    mapping(address => bool) public isDelegate;
    mapping(address => address) public delegateTo;
    mapping(address => uint256) public delegateVotingPower;
    mapping(address => uint256) public lastVoteTime;
    mapping(uint256 => uint256) public proposalCreationTime;
    mapping(uint256 => uint256) public proposalExecutionTime;
    mapping(uint256 => uint256) public proposalVotingTime;
    mapping(uint256 => uint256) public proposalRequiredVotes;
    mapping(uint256 => uint256) public proposalMinVotingPower;
    mapping(uint256 => uint256) public proposalExecutionDelay;
    mapping(uint256 => bool) public proposalIsActive;
    mapping(uint256 => uint256) public proposalVotesFor;
    mapping(uint256 => uint256) public proposalVotesAgainst;
    mapping(uint256 => bool) public proposalExecuted;
    mapping(uint256 => address) public proposalProposer;
    mapping(uint256 => string) public proposalDescription;
    mapping(uint256 => uint256) public proposalStartTime;
    mapping(uint256 => uint256) public proposalEndTime;
    mapping(uint256 => mapping(address => bool)) public proposalHasVoted;
    mapping(uint256 => mapping(address => uint256)) public proposalVotingPower;
    mapping(uint256 => string[]) public proposalOptions;
    mapping(uint256 => uint256[]) public proposalOptionVotes;
    mapping(uint256 => address[]) public proposalVoters;
    mapping(uint256 => uint256) public proposalTotalVotingPower;

    event ProposalCreated(uint256 indexed id, string description);
    event Voted(uint256 indexed id, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed id);
    event VotingPowerChanged(address indexed user, uint256 newPower);
    event DelegateRegistered(address indexed user, address indexed delegate);
    event ProposalOptionsUpdated(uint256 indexed id, string[] options);
    event ProposalVotingTimeUpdated(uint256 indexed id, uint256 newTime);
    event ProposalRequiredVotesUpdated(uint256 indexed id, uint256 newRequired);
    event ProposalMinVotingPowerUpdated(
        uint256 indexed id,
        uint256 newMinPower
    );
    event ProposalExecutionDelayUpdated(uint256 indexed id, uint256 newDelay);
    event ProposalIsActiveUpdated(uint256 indexed id, bool newIsActive);
    event ProposalVotesForUpdated(uint256 indexed id, uint256 newVotesFor);
    event ProposalVotesAgainstUpdated(
        uint256 indexed id,
        uint256 newVotesAgainst
    );
    event ProposalExecutedUpdated(uint256 indexed id, bool newExecuted);
    event ProposalProposerUpdated(uint256 indexed id, address newProposer);
    event ProposalDescriptionUpdated(uint256 indexed id, string newDescription);
    event ProposalStartTimeUpdated(uint256 indexed id, uint256 newStartTime);
    event ProposalEndTimeUpdated(uint256 indexed id, uint256 newEndTime);
    event ProposalHasVotedUpdated(
        uint256 indexed id,
        address indexed voter,
        bool newHasVoted
    );
    event ProposalVotingPowerUpdated(
        uint256 indexed id,
        address indexed voter,
        uint256 newVotingPower
    );
    event ProposalOptionsUpdated(uint256 indexed id, string[] newOptions);
    event ProposalOptionVotesUpdated(
        uint256 indexed id,
        uint256[] newOptionVotes
    );
    event ProposalVotersUpdated(uint256 indexed id, address[] newVoters);
    event ProposalTotalVotingPowerUpdated(
        uint256 indexed id,
        uint256 newTotalVotingPower
    );

    function createProposal(string memory desc) public {
        uint256 id = proposals.length;
        Proposal storage p = proposals.push();
        p.description = desc;
        p.votesFor = 0;
        p.votesAgainst = 0;
        p.executed = false;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + 7 days;
        p.proposer = msg.sender;
        p.requiredVotes = 1000;
        p.isActive = true;
        p.executionDelay = 1 days;
        p.minVotingPower = 100;
        p.totalVotingPower = 0;

        proposalCount[msg.sender]++;
        proposalCreationTime[msg.sender] = block.timestamp;
        proposalVotingTime[id] = 7 days;
        proposalRequiredVotes[uint256(id)] = 1000;
        proposalMinVotingPower[uint256(id)] = 100;
        proposalExecutionDelay[uint256(id)] = 1 days;
        proposalIsActive[uint256(id)] = true;
        proposalVotesFor[uint256(id)] = 0;
        proposalVotesAgainst[id] = 0;
        proposalExecuted[id] = false;
        proposalProposer[id] = msg.sender;
        proposalDescription[id] = desc;
        proposalStartTime[id] = block.timestamp;
        proposalEndTime[id] = block.timestamp + 7 days;
        proposalTotalVotingPower[id] = 0;

        emit ProposalCreated(id, desc);
    }

    function createProposalWithOptions(
        string memory desc,
        string[] memory options
    ) public {
        uint256 id = proposals.length;
        Proposal storage p = proposals.push();
        p.description = desc;
        p.votesFor = 0;
        p.votesAgainst = 0;
        p.executed = false;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + 7 days;
        p.proposer = msg.sender;
        p.requiredVotes = 1000;
        p.isActive = true;
        p.executionDelay = 1 days;
        p.minVotingPower = 100;
        p.totalVotingPower = 0;

        for (uint256 i = 0; i < options.length; i++) {
            p.options.push(options[i]);
            p.optionVotes.push(0);
        }

        proposalCount[msg.sender]++;
        proposalCreationTime[msg.sender] = block.timestamp;
        proposalVotingTime[id] = 7 days;
        proposalRequiredVotes[id] = 1000;
        proposalMinVotingPower[id] = 100;
        proposalExecutionDelay[id] = 1 days;
        proposalIsActive[id] = true;
        proposalVotesFor[id] = 0;
        proposalVotesAgainst[id] = 0;
        proposalExecuted[id] = false;
        proposalProposer[id] = msg.sender;
        proposalDescription[id] = desc;
        proposalStartTime[id] = block.timestamp;
        proposalEndTime[id] = block.timestamp + 7 days;
        proposalTotalVotingPower[id] = 0;

        for (uint256 i = 0; i < options.length; i++) {
            proposalOptions[id].push(options[i]);
            proposalOptionVotes[id].push(0);
        }

        emit ProposalCreated(id, desc);
        emit ProposalOptionsUpdated(id, options);
    }

    function vote(uint256 id, bool support) public {
        require(!voted[msg.sender][id], "Already voted");
        require(proposals[id].isActive, "Proposal not active");
        require(
            block.timestamp >= proposals[id].startTime,
            "Voting not started"
        );
        require(block.timestamp <= proposals[id].endTime, "Voting ended");
        require(
            votingPower[msg.sender] >= proposals[id].minVotingPower,
            "Insufficient voting power"
        );

        voted[msg.sender][id] = true;
        proposals[id].hasVoted[msg.sender] = true;
        proposals[id].votingPower[msg.sender] = votingPower[msg.sender];
        proposals[id].voters.push(msg.sender);
        proposals[id].totalVotingPower += votingPower[msg.sender];

        if (support) {
            proposals[id].votesFor += votingPower[msg.sender];
            proposalVotesFor[id] += votingPower[msg.sender];
        } else {
            proposals[id].votesAgainst += votingPower[msg.sender];
            proposalVotesAgainst[id] += votingPower[msg.sender];
        }

        lastVoteTime[msg.sender] = block.timestamp;
        proposalHasVoted[id][msg.sender] = true;
        proposalVotingPower[id][msg.sender] = votingPower[msg.sender];
        proposalVoters[id].push(msg.sender);
        proposalTotalVotingPower[id] += votingPower[msg.sender];

        emit Voted(id, msg.sender, support);
    }

    function voteWithOption(uint256 id, uint256 optionIndex) public {
        require(!voted[msg.sender][id], "Already voted");
        require(proposals[id].isActive, "Proposal not active");
        require(
            block.timestamp >= proposals[id].startTime,
            "Voting not started"
        );
        require(block.timestamp <= proposals[id].endTime, "Voting ended");
        require(
            votingPower[msg.sender] >= proposals[id].minVotingPower,
            "Insufficient voting power"
        );
        require(optionIndex < proposals[id].options.length, "Invalid option");

        voted[msg.sender][id] = true;
        proposals[id].hasVoted[msg.sender] = true;
        proposals[id].votingPower[msg.sender] = votingPower[msg.sender];
        proposals[id].voters.push(msg.sender);
        proposals[id].totalVotingPower += votingPower[msg.sender];
        proposals[id].optionVotes[optionIndex] += votingPower[msg.sender];

        lastVoteTime[msg.sender] = block.timestamp;
        proposalHasVoted[id][msg.sender] = true;
        proposalVotingPower[id][msg.sender] = votingPower[msg.sender];
        proposalVoters[id].push(msg.sender);
        proposalTotalVotingPower[id] += votingPower[msg.sender];
        proposalOptionVotes[id][optionIndex] += votingPower[msg.sender];

        emit Voted(id, msg.sender, true);
    }

    function executeProposal(uint256 id) public {
        Proposal storage p = proposals[id];
        require(!p.executed, "Already executed");
        require(p.votesFor > p.votesAgainst, "Not enough support");
        require(p.totalVotingPower >= p.requiredVotes, "Not enough votes");
        require(
            block.timestamp >= p.endTime + p.executionDelay,
            "Execution delay not met"
        );

        p.executed = true;
        proposalExecuted[id] = true;
        proposalExecutionTime[id] = block.timestamp;

        emit ProposalExecuted(id);
    }

    function setVotingPower(uint256 power) public {
        votingPower[msg.sender] = power;
        emit VotingPowerChanged(msg.sender, power);
    }

    function registerDelegate(address delegate) public {
        isDelegate[msg.sender] = true;
        delegateTo[msg.sender] = delegate;
        delegateVotingPower[delegate] += votingPower[msg.sender];
        emit DelegateRegistered(msg.sender, delegate);
    }

    function updateProposalOptions(uint256 id, string[] memory options) public {
        require(proposals[id].proposer == msg.sender, "Not proposer");
        require(!proposals[id].executed, "Already executed");
        require(
            block.timestamp < proposals[id].startTime,
            "Voting already started"
        );

        proposals[id].options = options;
        proposalOptions[id] = options;

        emit ProposalOptionsUpdated(id, options);
    }

    function updateProposalVotingTime(uint256 id, uint256 newTime) public {
        require(proposals[id].proposer == msg.sender, "Not proposer");
        require(!proposals[id].executed, "Already executed");
        require(
            block.timestamp < proposals[id].startTime,
            "Voting already started"
        );

        proposals[id].endTime = proposals[id].startTime + newTime;
        proposalVotingTime[id] = newTime;
        proposalEndTime[id] = proposals[id].startTime + newTime;

        emit ProposalVotingTimeUpdated(id, newTime);
    }

    function updateProposalRequiredVotes(
        uint256 id,
        uint256 newRequired
    ) public {
        require(proposals[id].proposer == msg.sender, "Not proposer");
        require(!proposals[id].executed, "Already executed");
        require(
            block.timestamp < proposals[id].startTime,
            "Voting already started"
        );

        proposals[id].requiredVotes = newRequired;
        proposalRequiredVotes[id] = newRequired;

        emit ProposalRequiredVotesUpdated(id, newRequired);
    }

    function updateProposalMinVotingPower(
        uint256 id,
        uint256 newMinPower
    ) public {
        require(proposals[id].proposer == msg.sender, "Not proposer");
        require(!proposals[id].executed, "Already executed");
        require(
            block.timestamp < proposals[id].startTime,
            "Voting already started"
        );

        proposals[id].minVotingPower = newMinPower;
        proposalMinVotingPower[id] = newMinPower;

        emit ProposalMinVotingPowerUpdated(id, newMinPower);
    }

    function updateProposalExecutionDelay(uint256 id, uint256 newDelay) public {
        require(proposals[id].proposer == msg.sender, "Not proposer");
        require(!proposals[id].executed, "Already executed");
        require(
            block.timestamp < proposals[id].startTime,
            "Voting already started"
        );

        proposals[id].executionDelay = newDelay;
        proposalExecutionDelay[id] = newDelay;

        emit ProposalExecutionDelayUpdated(id, newDelay);
    }

    function updateProposalIsActive(uint256 id, bool newIsActive) public {
        require(proposals[id].proposer == msg.sender, "Not proposer");
        require(!proposals[id].executed, "Already executed");

        proposals[id].isActive = newIsActive;
        proposalIsActive[id] = newIsActive;

        emit ProposalIsActiveUpdated(id, newIsActive);
    }

    // === LENDING SECTION ===
    struct Loan {
        address borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 term;
        uint256 startTime;
        uint256 endTime;
        bool repaid;
        uint256 collateralAmount;
        address collateralToken;
        uint256 lastPaymentTime;
        uint256 totalPaid;
        uint256 remainingAmount;
        uint256 lateFees;
        bool isLiquidated;
        address liquidator;
        uint256 liquidationTime;
        uint256 liquidationAmount;
        uint256 liquidationPrice;
        uint256 healthFactor;
        uint256 maxLTV;
        uint256 liquidationThreshold;
        uint256 liquidationPenalty;
        uint256 gracePeriod;
        uint256 minimumPayment;
        uint256 paymentFrequency;
        uint256 missedPayments;
        uint256 nextPaymentDue;
        uint256 totalInterest;
        uint256 principalPaid;
        uint256 interestPaid;
        uint256 feesPaid;
        uint256 lastHealthCheck;
        uint256 lastInterestAccrual;
        uint256 accruedInterest;
        uint256 lastPaymentAmount;
        uint256 lastPaymentPrincipal;
        uint256 lastPaymentInterest;
        uint256 lastPaymentFees;
        uint256 lastPaymentLateFees;
        uint256 lastPaymentTimestamp;
        uint256 lastPaymentBlock;
        uint256 lastPaymentGasUsed;
        uint256 lastPaymentGasPrice;
        uint256 lastPaymentGasLimit;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public userLoans;
    uint256 public totalLoans;
    uint256 public activeLoanCount;

    event LoanCreated(
        uint256 indexed id,
        address indexed borrower,
        uint256 amount
    );
    event LoanRepaid(
        uint256 indexed id,
        address indexed borrower,
        uint256 amount
    );
    event LoanLiquidated(
        uint256 indexed id,
        address indexed liquidator,
        uint256 amount
    );

    function createLoan(
        uint256 amount,
        uint256 interestRate,
        uint256 term,
        uint256 collateralAmount,
        address collateralToken
    ) public returns (uint256) {
        require(amount > 0, "Invalid amount");
        require(interestRate > 0, "Invalid interest rate");
        require(term > 0, "Invalid term");
        require(collateralAmount > 0, "Invalid collateral");

        uint256 loanId = totalLoans++;
        Loan storage loan = loans[loanId];

        loan.borrower = msg.sender;
        loan.amount = amount;
        loan.interestRate = interestRate;
        loan.term = term;
        loan.startTime = block.timestamp;
        loan.endTime = block.timestamp + term;
        loan.collateralAmount = collateralAmount;
        loan.collateralToken = collateralToken;
        loan.healthFactor = 100;
        loan.maxLTV = 80;
        loan.liquidationThreshold = 85;
        loan.liquidationPenalty = 10;
        loan.gracePeriod = 3 days;
        loan.minimumPayment = amount / term;
        loan.paymentFrequency = 30 days;
        loan.nextPaymentDue = block.timestamp + 30 days;

        userLoans[msg.sender].push(loanId);
        activeLoanCount++;

        emit LoanCreated(loanId, msg.sender, amount);
        return loanId;
    }

    function repayLoan(uint256 loanId, uint256 amount) public {
        Loan storage loan = loans[loanId];
        require(loan.borrower == msg.sender, "Not borrower");
        require(!loan.repaid, "Already repaid");
        require(amount > 0, "Invalid amount");

        loan.totalPaid += amount;
        loan.remainingAmount =
            loan.amount +
            loan.accruedInterest -
            loan.totalPaid;
        loan.lastPaymentTime = block.timestamp;
        loan.lastPaymentAmount = amount;

        if (loan.remainingAmount == 0) {
            loan.repaid = true;
            activeLoanCount--;
            emit LoanRepaid(loanId, msg.sender, amount);
        }
    }

    function liquidateLoan(uint256 loanId) public {
        Loan storage loan = loans[loanId];
        require(!loan.repaid, "Already repaid");
        require(!loan.isLiquidated, "Already liquidated");
        require(
            loan.healthFactor < loan.liquidationThreshold,
            "Cannot liquidate"
        );

        loan.isLiquidated = true;
        loan.liquidator = msg.sender;
        loan.liquidationTime = block.timestamp;
        loan.liquidationAmount = loan.remainingAmount;
        loan.liquidationPrice =
            (loan.collateralAmount * loan.liquidationPenalty) /
            100;

        activeLoanCount--;
        emit LoanLiquidated(loanId, msg.sender, loan.liquidationAmount);
    }

    // === ANALYTICS SECTION ===
    struct Analytics {
        uint256 timestamp;
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 uniqueUsers;
        uint256 averageTransactionSize;
        uint256 largestTransaction;
        address mostActiveUser;
        uint256 mostActiveUserTransactions;
        uint256 totalFees;
        uint256 averageFees;
        uint256 totalGasUsed;
        uint256 averageGasUsed;
        uint256 successRate;
        uint256 failureRate;
        uint256[] transactionSizes;
        address[] activeUsers;
        uint256[] gasPrices;
        uint256[] blockTimes;
    }

    Analytics[] public analyticsHistory;
    mapping(uint256 => Analytics) public dailyAnalytics;
    mapping(uint256 => Analytics) public weeklyAnalytics;
    mapping(uint256 => Analytics) public monthlyAnalytics;

    function updateAnalytics() internal {
        uint256 timestamp = block.timestamp;
        Analytics storage daily = dailyAnalytics[timestamp / 1 days];
        Analytics storage weekly = weeklyAnalytics[timestamp / 1 weeks];
        Analytics storage monthly = monthlyAnalytics[timestamp / 30 days];

        daily.timestamp = timestamp;
        daily.totalTransactions++;
        daily.totalVolume += msg.value;
        daily.uniqueUsers++;
        daily.averageTransactionSize =
            daily.totalVolume /
            daily.totalTransactions;
        daily.totalGasUsed += gasleft();
        daily.averageGasUsed = daily.totalGasUsed / daily.totalTransactions;

        weekly.timestamp = timestamp;
        weekly.totalTransactions++;
        weekly.totalVolume += msg.value;
        weekly.uniqueUsers++;
        weekly.averageTransactionSize =
            weekly.totalVolume /
            weekly.totalTransactions;
        weekly.totalGasUsed += gasleft();
        weekly.averageGasUsed = weekly.totalGasUsed / weekly.totalTransactions;

        monthly.timestamp = timestamp;
        monthly.totalTransactions++;
        monthly.totalVolume += msg.value;
        monthly.uniqueUsers++;
        monthly.averageTransactionSize =
            monthly.totalVolume /
            monthly.totalTransactions;
        monthly.totalGasUsed += gasleft();
        monthly.averageGasUsed =
            monthly.totalGasUsed /
            monthly.totalTransactions;
    }
}
