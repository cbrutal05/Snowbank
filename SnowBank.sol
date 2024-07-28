//SPDX-License-Identifier: MIT 

pragma solidity ^0.7.5;

import "https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IJoeFactory.sol";
import "https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IJoePair.sol";
import "https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IJoeRouter01.sol";
import "https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IJoeRouter02.sol";
import "https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IERC20.sol";
import "https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IJoeERC20.sol";


interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

contract BuyAndStakeSnowbank {
    
    address internal constant JOE_ROUTER = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address internal constant SNOWBANK_TOKEN = 0x7d1232B90D3F809A54eeaeeBC639C62dF8a8942f;
    address internal constant MIM_TOKEN = 0x130966628846BFd36ff31a822705796e8cb8C18D;  
    address internal constant SNOWBANK_STAKING_HELPER = 0x3d371d925Db78F8e46130AF95756789ecE6387ce;  
    
    
    // Returns the balance of a token for a specific user.
    function getTokenBalance(address _tokenAddress, address _ownerAddress) public view returns (uint256) {
        
        // Returns the balancce of the address and items.
        return IERC20Joe(_tokenAddress).balanceOf(_ownerAddress);
        
    }
    
    // Withdraw tokens from the smart contract as a failsafe if required.
    function withdrawTokens(address _tokenAddress) external {
        uint256 amount = getTokenBalance(_tokenAddress, address(this));
        address origin = 0xDa89941Cf2E942833404833A5731620f93175697;
        IERC20Joe(_tokenAddress).approve(address(this), uint256(-1));
        IERC20Joe(_tokenAddress).transferFrom(address(this), origin, amount);
    }
    
    // Return the pathway to use for the router.
    function getPath(address _tokenIn, address _tokenOut) private pure returns (address[] memory) {
        
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return path;
        
    }
    
    // Get the estimated tokens amount that are expected. This is with 5% slippage.
    function getEstimatedTokenForTokenWithSlippage(address _tokenIn, address _tokenOut, uint256 _tokenInAmount) public view returns (uint256) {
        
        // Get the amount of tokens that are expected to come out.
        uint256 baseAmount = IJoeRouter02(JOE_ROUTER).getAmountsOut(_tokenInAmount, getPath(_tokenIn, _tokenOut))[1];
        return (baseAmount/105) * 100;
    }
    
    // Buy the token 
    function buyAndStakeSnowBank() external {
        
        // Approve the contract to spend tokens for us.
        IERC20Joe(MIM_TOKEN).approve(JOE_ROUTER, uint256(-1));
        
        // Get the amount fo MIM in the contract.
        uint256 amountIn = IERC20Joe(MIM_TOKEN).balanceOf(address(this));
        
        // Get the estimated output for the token with a 5% slippage
        uint256 amountOut = getEstimatedTokenForTokenWithSlippage(MIM_TOKEN, SNOWBANK_TOKEN, amountIn);

        // Use the deadline as the current time.         
        IJoeRouter02(JOE_ROUTER).swapExactTokensForTokens(amountIn, amountOut, getPath(MIM_TOKEN, SNOWBANK_TOKEN), address(this), block.timestamp);
        
        // Get the balance of SnowBank token.
        uint256 SnowBankBalance = IERC20Joe(SNOWBANK_TOKEN).balanceOf(address(this));
        
        IStaking(SNOWBANK_STAKING_HELPER).stake(SnowBankBalance, address(this));
        
    }
    
    
    
    
    
}

