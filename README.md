# SOLIDINTEREST

## Overview

SolidInterest allows you to grow a certain ERC20 token by a fixed amount per second. This uses upgradeable contracts and an interest bearing token, as well as a streamable token using Superfluid.

This is a powerful tool for anyone that wants to track an interest accrual, transfer its ownership and build on the back their yield protocol.

This repo does not back the interest with any yield generating strategy, but the possibilities are endless as you simply need to guarantee the interest to the user, anything else that you earn on the deposited funds is profit!

## Test

Fill in the env file and test on Goerli fork by running:

cd packages/hardhat
forge test
