# Need liquidity token, need reserve token, need olympus token
import os
import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.Signer import Signer

signer = Signer(123456789987654321)


def uint(a):
    return(a, 0)


def str_to_felt(text):
    b_text = bytes(text, 'UTF-8')
    return int.from_bytes(b_text, "big")


@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


# The path to the contract source code.
TREASURY_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/Treasury.cairo")


@pytest.fixture(scope="module")
async def olympusFactory():
    user = 789
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()
    # Deploy the contract.
    contract = await starknet.deploy(
        source='../contracts/OlympusERC20.Cairo',
        constructor_calldata=[str_to_felt(
            "Olympus"), str_to_felt("OHM"), user, user]
    )

    return contract, user


@pytest.fixture()
async def treasuryFactory(olympusFactory):

    ohmContract, user = olympusFactory
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()
    # Deploy the contract.
    contract = await starknet.deploy(
        source='../contracts/Treasury.Cairo',
        constructor_calldata=[user, ohmContract.contract_address]
    )
    return contract, ohmContract, user


@pytest.fixture(scope="module")
async def erc20Factory():

    user = 789
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()
    # Deploy the contract.
    contract = await starknet.deploy(
        source='../contracts/ERC20.Cairo',
        constructor_calldata=[str_to_felt("erc20"), str_to_felt("ERC20"), user]
    )

    return contract


@pytest.mark.asyncio
async def test_deposit_not_reserve_or_liquidity(olympusFactory, treasuryFactory, erc20Factory):

    treasuryContract, ohmContract, user = treasuryFactory

    erc20 = erc20Factory

    print("address is " + str(ohmContract.contract_address))
    exec_data = await treasuryContract.deposit(
        amount=uint(10), token_address=ohmContract.contract_address, profit=uint(1)).call()

    assert exec_data.result.res == uint(90)
