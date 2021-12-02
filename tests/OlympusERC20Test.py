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

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.


@pytest.mark.asyncio
async def test_OHM_burn(olympusFactory):

    contract, user = olympusFactory
    # Store pens and paper twice.
    await contract.burn(amount=uint(100), user=user).invoke()

    # Check the result of check_items().
    exec_data = await contract.balance_of(
        account=user).call()

    assert exec_data.result.res == (uint(900))
