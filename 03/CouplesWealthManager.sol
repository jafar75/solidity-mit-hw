// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract WealthManagerCouple {

    // <contract_variables>
    address[] public owners;
    bool public first_approved_second;
    bool public second_approved_first;
    uint256 public approval_amount;

    uint256 constant public withdraw_limit = 0.001 ether;
    // </contract_variables>

    modifier onlyOwners {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner == true, "only owners can use the contract!!!!!");
        _;
    }

    constructor (address partner2) payable {
        owners.push(msg.sender);
        owners.push(partner2);

        first_approved_second = false;
        second_approved_first = false;

        approval_amount = 0;
    }

    function withdraw(uint256 amount) onlyOwners public {
        require (address(this).balance >= amount, "amount is greater than contract ETH balance!");
        bool has_approval = (msg.sender == owners[0] && second_approved_first) 
            || (msg.sender == owners[1] && first_approved_second);

        if (has_approval) {
            require (amount <= approval_amount, "required amount to withdraw exceeds the approval max amount!!");
            payable(msg.sender).transfer(amount);
            approval_amount = approval_amount - amount;
            if (approval_amount <= withdraw_limit) {
                first_approved_second = second_approved_first = false;
                approval_amount = 0;
            }
        } else {
            require (amount <= withdraw_limit, "amount exceeds the withdraw limit! you need to get approve of other partner!!");
            payable(msg.sender).transfer(amount);
        }
    }

    function sign(uint256 maxAmount) onlyOwners public {
        require ((first_approved_second || second_approved_first) == false, "only one approval can be existed at any time!!");

        require (maxAmount > withdraw_limit, "for values less than default limit, no additional approval is needed!");

        approval_amount = maxAmount;

        if (msg.sender == owners[0]) {
            first_approved_second = true;
        } else {
            second_approved_first = true;
        }
    }

    receive () external payable {
        // TODO
    }

}