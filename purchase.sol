// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract OnlinePurchaseAgreement {
    uint256 public price;
    uint256 public sent;
    address payable public buyer;
    address payable public seller;

    enum PurchaseStatus {
        CREATED,
        LOCKED,
        ITEM_RECEIVED,
        COMPLETED,
        INACTIVE,
        FAILED
    }

    PurchaseStatus public purchaseStatus;

    event ContractLocked(
        address indexed buyer,
        address indexed seller,
        uint256 purchageAmount,
        PurchaseStatus status
    );
    event ItemReceived(
        address indexed buyer,
        address indexed seller,
        uint256 purchageAmount,
        PurchaseStatus status
    );
    event ContractCompleted(
        address indexed buyer,
        address indexed seller,
        uint256 purchageAmount,
        PurchaseStatus status
    );
    event ContractAborted(address indexed buyer, PurchaseStatus status);

    modifier inState(PurchaseStatus _status) {
        require(
            purchaseStatus == _status,
            "Cant run this function in current state."
        );
        _;
    }

    constructor() payable {
        price = msg.value;

        seller = payable(msg.sender);
    }

    // modifier to check if msg.sender is the seller
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    /**
     * @dev allows a user to purchase the item
     * @notice the amount sent needs to be twice the purchase amount
     */
    function confirmPurchase()
        public
        payable
        inState(PurchaseStatus.CREATED)
    {
        require(
            msg.value == 2 * price,
            "Please send twice the purchase amount"
        );

        buyer = payable(msg.sender);
        sent = msg.value;
        purchaseStatus = PurchaseStatus.LOCKED;

        emit ContractLocked(buyer, seller, sent, purchaseStatus);
    }

    /**
     * @dev allows the buyer to confirm that he received the item and returns back the price amount
     */
    function confirmReceived() public payable inState(PurchaseStatus.LOCKED) {
        require(msg.sender == buyer, "Only buyer can call this method");
        purchaseStatus = PurchaseStatus.ITEM_RECEIVED;
        uint256 amount = price;
        price = 0;
        (bool success, ) = payable(buyer).call{value: amount}("");
        require(success, "Transfer failed");
        emit ItemReceived(buyer, seller, amount, purchaseStatus);
    }

    /**
     * @dev allows the seller to retrieve his initial deposit amount and the price amount through the amount stored in sent
     */
    function paySeller()
        public
        inState(PurchaseStatus.ITEM_RECEIVED)
        onlySeller
    {
        purchaseStatus = PurchaseStatus.COMPLETED;
        uint256 amount = sent;
        sent = 0;
        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");
        emit ContractCompleted(buyer, seller, amount, purchaseStatus);
    }

    /**
     * @dev allows the seller to abort the sale and return back the initial deposit made during deployment
     */
    function abort() public payable inState(PurchaseStatus.CREATED) onlySeller {
        purchaseStatus = PurchaseStatus.INACTIVE;
        uint256 amount = price;
        price = 0;
        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");
        emit ContractAborted(seller, purchaseStatus);
    }
}
