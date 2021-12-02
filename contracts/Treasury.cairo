%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_signed_nn, uint256_mul)

from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

#
# ERC20 Interface
#

@contract_interface
namespace IERC20:
    func get_total_supply() -> (res : Uint256):
    end

    func get_decimals() -> (res : felt):
    end

    func balance_of(account : felt) -> (res : Uint256):
    end

    func allowance(owner : felt, spender : felt) -> (res : Uint256):
    end

    func transfer(recipient : felt, amount : Uint256):
    end

    func transfer_from(sender : felt, recipient : felt, amount : Uint256):
    end

    func approve(spender : felt, amount : Uint256):
    end

    func mint(recipient : felt, amount : Uint256) -> ():
    end
end

@contract_interface
namespace IOHMERC20:
    func get_total_supply() -> (res : Uint256):
    end

    func get_decimals() -> (res : felt):
    end

    func balance_of(account : felt) -> (res : Uint256):
    end

    func allowance(owner : felt, spender : felt) -> (res : Uint256):
    end

    func transfer(recipient : felt, amount : Uint256):
    end

    func transfer_from(sender : felt, recipient : felt, amount : Uint256):
    end

    func approve(spender : felt, amount : Uint256):
    end

    func mint(recipient : felt, amount : Uint256) -> ():
    end

    func burnFrom(spender : felt, owner : felt, amount : Uint256) -> ():
    end
end

#
#   IBondCalculatorInterface
#
@contract_interface
namespace IBondCalculator:
    func valuation(_pair : felt, amount : Uint256) -> (value : Uint256):
    end
end

#
# Storage Var
#

# # Ownable Storage Var
@storage_var
func _owner() -> (res : felt):
end

# # Treasury Storage
@storage_var
func _ohm_address() -> (res : felt):
end

@storage_var
func _bond_calculator_address() -> (res : felt):
end

@storage_var
func _blocks_needed_for_queue() -> (res : felt):
end

@storage_var
func _reserve_tokens(index : felt) -> (res : felt):
end

@storage_var
func _is_reserve_token(address : felt) -> (res : felt):
end

@storage_var
func _reserve_token_queue(address : felt) -> (res : felt):
end

@storage_var
func _reserve_depositors(index : felt) -> (res : felt):
end

@storage_var
func _is_depositor(address : felt) -> (res : felt):
end

@storage_var
func _reserve_depositor_queue(address : felt) -> (res : felt):
end

@storage_var
func _reserve_spender(index : felt) -> (res : felt):
end

@storage_var
func _is_reserve_spender(address : felt) -> (res : felt):
end

@storage_var
func _reserve_spender_queue(address : felt) -> (res : felt):
end

@storage_var
func _liquidity_tokens(index : felt) -> (res : felt):
end

@storage_var
func _is_liquidity_token(address : felt) -> (res : felt):
end

@storage_var
func _liquidity_token_queue(address : felt) -> (res : felt):
end

@storage_var
func _liquidity_depositors(address : felt) -> (res : felt):
end

@storage_var
func _is_liquidity_depositor(address : felt) -> (res : felt):
end

@storage_var
func _liquidity_depositor_queue(address : felt) -> (res : felt):
end

@storage_var
func _bond_calculator(addess : felt) -> (res : felt):
end

@storage_var
func _reserve_managers(address : felt) -> (res : felt):
end

@storage_var
func _is_reserve_manager(address : felt) -> (res : felt):
end

@storage_var
func _reservce_manager_queue(address : felt) -> (res : felt):
end

@storage_var
func _liquidity_managers(address : felt) -> (res : felt):
end

@storage_var
func _is_liquidity_manager(address : felt) -> (res : felt):
end

@storage_var
func _liquidity_manager_queue(address : felt) -> (res : felt):
end

@storage_var
func _debtors(address : felt) -> (res : felt):
end

@storage_var
func _is_debtor(address : felt) -> (res : felt):
end

@storage_var
func _debtor_queue(address : felt) -> (res : felt):
end

@storage_var
func _debtor_balance(address : felt) -> (res : felt):
end

@storage_var
func _reward_managers(address : felt) -> (res : felt):
end

@storage_var
func is_reward_manager(address : felt) -> (res : felt):
end

@storage_var
func _reward_manager_queue(address : felt) -> (res : felt):
end

@storage_var
func _sOHM_queue() -> (res : felt):
end

@storage_var
func _total_reserves() -> (res : Uint256):
end

@storage_var
func _total_debt() -> (res : Uint256):
end

#
# Getters
#

# # Ownable Getters

@view
func get_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : felt):
    let (res) = _owner.read()
    return (res=res)
end

@view
func only_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (owner) = _owner.read()
    let (caller) = get_caller_address()
    assert owner = caller
    return ()
end

#
# Constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        initial_owner : felt, ohm_address):
    _owner.write(initial_owner)
    _ohm_address.write(ohm_address)
    return ()
end

#
# Internals
#
func pow(base : felt, exp : felt) -> (res):
    if exp == 0:
        return (res=1)
    end
    let (res) = pow(base=base, exp=exp - 1)
    return (res=res * base)
end
#
# External
#

# # Ownable External
@external
func transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        new_owner : felt) -> (new_owner : felt):
    only_owner()
    _owner.write(new_owner)
    return (new_owner=new_owner)
end

# # Treasury External
@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : Uint256, token_address : felt, profit : Uint256) -> (send : Uint256):
    alloc_locals

    let (ohm_address) = _ohm_address.read()
    let (ohm_decimals) = IERC20.get_decimals(ohm_address)

    assert_not_zero(ohm_decimals)

    let (is_liquidity_token) = _is_liquidity_token.read(token_address)
    assert_not_zero(is_liquidity_token)

    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    # # This ought to be a safe transfer
    IERC20.transfer_from(
        contract_address=ohm_address,
        sender=caller_address,
        recipient=contract_address,
        amount=amount)

    let (local value) = valueOf(amount, token_address)

    let (send) = uint256_sub(value, profit)

    let (ohm_address) = _ohm_address.read()

    IERC20.mint(contract_address=ohm_address, recipient=caller_address, amount=send)

    let (current_reserves) = _total_reserves.read()

    let (updated_reserves, _) = uint256_add(current_reserves, send)
    _total_reserves.write(updated_reserves)

    return (value)
end

@external
func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : Uint256, token : felt) -> ():
    alloc_locals
    let (is_reserve_token) = _is_reserve_token.read(token)
    assert is_reserve_token = 1

    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (ohm_address) = _ohm_address.read()

    let (is_reserve_spender) = _is_reserve_spender.read(caller_address)

    let (value) = valueOf(amount, token)

    IOHMERC20.burnFrom(
        contract_address=ohm_address, spender=caller_address, owner=contract_address, amount=value)

    let (total_reserves) = _total_reserves.read()

    let (updated_reserves) = uint256_sub(total_reserves, value)
    IOHMERC20.transfer(contract_address=token, recipient=caller_address, amount=amount)

    return ()
end

@external
func valueOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : Uint256, token_address : felt) -> (value : Uint256):
    alloc_locals

    let value : Uint256 = Uint256(0, 0)

    let (is_reserve_token) = _is_reserve_token.read(token_address)
    if is_reserve_token == 1:
        let (ohm_address) = _ohm_address.read()
        let (ohm_decimals) = IERC20.get_decimals(contract_address=ohm_address)
        let (token_decimals) = IERC20.get_decimals(contract_address=token_address)

        let (ohm_exp) = pow(10, ohm_decimals)
        let (token_exp) = pow(10, token_decimals)

        local ratio : Uint256 = Uint256(ohm_exp / token_exp, 0)
        let (value, _) = uint256_mul(amount, ratio)

        return (value)
    end

    let (is_liquidity_token) = _is_liquidity_token.read(token_address)

    if is_liquidity_token == 1:
        let (bond_calculator_address) = _bond_calculator_address.read()
        let (bondPrice) = _bond_calculator.read(token_address)
        let (value) = IBondCalculator.valuation(
            contract_address=bond_calculator_address, _pair=token_address, amount=amount)
        return (value)
    end
    return (value)
end
