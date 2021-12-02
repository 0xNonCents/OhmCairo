%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IBondCalculator:
    func valuation(_pair : felt, amount : Uint256) -> (value : Uint256):
    end
end
