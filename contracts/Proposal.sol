// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

pragma solidity ^0.8.0;

contract BaseVersion is Initializable {
    function _version() internal view virtual returns (uint8) {
        return 1;
    }

    function version() public view returns (uint8) {
        return _version();
    }

    function upgrade() public virtual {
        _upgradeFrom(_getInitializedVersion());
    }

    function _upgradeFrom(uint8 version_) internal virtual {
        // Silencing warning
        version_;
        revert("BaseVersion: No upgrade function defined");
    }

    modifier requireVersion(uint8 _minimum) {
        require(
            _getInitializedVersion() >= _minimum,
            string(
                abi.encodePacked(
                    "BeaconVersion: Your contract is out of date - needed: ",
                    _minimum,
                    " currently: ",
                    _getInitializedVersion()
                )
            )
        );
        _;
    }
}

contract MajorVersion is BaseVersion {
    function _upgradeFrom(uint8 version_) internal virtual override {
        // Silencing warning
        super._upgradeFrom(version_);
    }
}

// Is base version so doesnt need to implement upgrade methods, should correclty revert
contract ContractV1 is MajorVersion {
    string private someString;

    function __ContractV1_initialize() internal onlyInitializing {
        someString = "Some value";
    }

    function initialize() public virtual initializer {
        __ContractV1_initialize();
    }

    function echoString() public view virtual returns (string memory) {
        return someString;
    }
}

contract ContractV2 is MajorVersion, ContractV1 {
    uint8 private constant v2 = 2;

    function _version() internal view virtual override returns (uint8) {
        return v2;
    }

    function _upgradeFrom(uint8 version_) internal virtual override {
        // If is more out-of-date than previous version
        // would never happen in this case cause it would be version 1
        // but placed it here for consistency
        if (version_ < v2 - 1) {
            super._upgradeFrom(version_);
        }
        initializeV2();
    }

    uint256 private someInt;

    function __ContractV2_initialize_unchained() internal onlyInitializing {
        someInt = 11;
    }

    function __ContractV2_initialize() internal onlyInitializing {
        super.__ContractV1_initialize();
        __ContractV2_initialize_unchained();
    }

    function initialize() public virtual override reinitializer(2) {
        __ContractV2_initialize();
    }

    function initializeV2() public reinitializer(v2) {
        __ContractV2_initialize_unchained();
    }

    function echoInt() public view requireVersion(v2) returns (uint256) {
        return someInt;
    }
}

contract ContractV3 is MajorVersion, ContractV2 {
    uint8 private constant v3 = 3;

    function _version()
        internal
        view
        virtual
        override(BaseVersion, ContractV2)
        returns (uint8)
    {
        return v3;
    }

    function _upgradeFrom(
        uint8 version_
    ) internal virtual override(MajorVersion, ContractV2) {
        // If is more out-of-date than previous version
        if (version_ < v3 - 1) {
            ContractV2._upgradeFrom(version_);
        }
        initializeV3();
    }

    string private v3string;

    function __ContractV3_initialize_unchained() internal onlyInitializing {
        v3string = "v3 is here";
    }

    function __ContractV3_initialize() internal onlyInitializing {
        __ContractV2_initialize();
        __ContractV3_initialize_unchained();
    }

    function initialize() public override reinitializer(v3) {
        __ContractV3_initialize();
    }

    function initializeV3() public reinitializer(v3) {
        __ContractV3_initialize_unchained();
    }

    function echoString()
        public
        view
        virtual
        override
        requireVersion(v3)
        returns (string memory)
    {
        return v3string;
    }
}
