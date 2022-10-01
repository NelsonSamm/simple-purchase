// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


contract OnlinePurchaseAgreement {

    uint256 public value;
    address payable public buyer;
    address payable public seller;

    enum PurchaseStatus{
        CREATED,
        LOCKED,
        ITEM_RECEIVED,
        COMPLETED,
        INACTIVE,
        FAILED
    }

    PurchaseStatus public purchaseStatus;

    event ContractLocked(address indexed buyer, address indexed seller, uint256 purchageAmount, PurchaseStatus status);
    event ItemReceived(address indexed buyer, address indexed seller, uint256 purchageAmount, PurchaseStatus status);
    event ContractCompleted(address indexed buyer, address indexed seller, uint256 purchageAmount, PurchaseStatus status);
    event ContractAborted(address indexed buyer, PurchaseStatus status);

    modifier inState(PurchaseStatus _status) {
        require(purchaseStatus == _status,"Cant run this function in current state." );
        _;
    }

    constructor(uint256 _value) payable {
        require(_value == msg.value, "Please send correct amount. Same as purchase amount");
        value = _value; 
        seller = payable(msg.sender);
    }

    function confirmPurchase() external payable inState(PurchaseStatus.CREATED){
        require(msg.value == 2*value, "Please send twice the purchase amount");
        buyer = payable(msg.sender);
        purchaseStatus = PurchaseStatus.LOCKED;
        emit ContractLocked(buyer, seller, value, purchaseStatus);   
    }

    function confirmReceived() external inState(PurchaseStatus.LOCKED) {
        require(msg.sender==buyer,"Only buyer can call this method");
        purchaseStatus = PurchaseStatus.ITEM_RECEIVED;
        sendEther(buyer, value);
        paySeller();
        emit ItemReceived(buyer, seller, value, purchaseStatus);
    }

    function paySeller() internal inState(PurchaseStatus.ITEM_RECEIVED) {
        purchaseStatus = PurchaseStatus.COMPLETED;
        sendEther(seller, value);
        emit ContractCompleted(buyer, seller, value, purchaseStatus);
    }

    function abort() external inState(PurchaseStatus.CREATED){
        require(msg.sender==seller,"Only seller can call this method");
        purchaseStatus = PurchaseStatus.INACTIVE;
        sendEther(seller, value);
        emit ContractAborted(buyer, purchaseStatus);
    }

    function sendEther(address payable to, uint256 _value) internal {
        bool sent = to.send(_value);
        require(sent, "Failed to transfer eth");
    }
}