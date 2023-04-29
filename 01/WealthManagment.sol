// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract WealthManager {

    // <contract_variables>
    address[] public owners;
    address public heir;
    bool is_active;

    uint256 constant public withdraw_limit = 0.001 ether;
    uint256 constant public inactive_interval = 70 seconds;
    uint256 public last_access_time;

    // </contract_variables>

    modifier onlyOwners {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner == true, "only owners can withdraw");
        _;
    }

    modifier mustActive {
        require(is_active == true, "the balance has transfered to the heir!!");
        _;
    }

    constructor(address _partner, address _heir) payable {
        owners.push(msg.sender);
        owners.push(_partner);

        heir = _heir;

        is_active = true;

        saveTimeStamp();
    }

    function saveTimeStamp() private {
        last_access_time = block.timestamp;
    }

    function withdraw(uint256 amount) mustActive onlyOwners public {
        require (amount <= withdraw_limit, "at most 1 ether can be withdrawed at once");
        require (amount <= address(this).balance, "contract balance is less than the required amount");

        payable(msg.sender).transfer(amount);

        saveTimeStamp();
    }

    function inherit() mustActive public {
        require (msg.sender == heir, "only heir can inherit the ethers!!");

        require (block.timestamp >= (last_access_time + inactive_interval), "only after at least 1 year from the last withdraw");

        payable(heir).transfer(address(this).balance);

        is_active = false;
    }

    receive () mustActive external payable {
        saveTimeStamp();
    }
}