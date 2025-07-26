import React, { createContext, useContext, useEffect, useState } from 'react';
import { ethers } from 'ethers';
import VottingSystem from '../contracts/VottingSystem.json';

const Web3Context = createContext();

export const Web3Provider = ({ children }) => {
  const [account, setAccount] = useState(null);
  const [contract, setContract] = useState(null);
  const [provider, setProvider] = useState(null);
  const [isOwner, setIsOwner] = useState(false);
  const [isSubscribed, setIsSubscribed] = useState(false);
  const [stakedAmount, setStakedAmount] = useState(0);
  const [loading, setLoading] = useState(true);

  // Contract Address and ABI
  const contractAddress = "0x8A8A78145ceE1f9FBAbEA2D2b16fc3f945CB5E90";
  const contractABI = VottingSystem.abi;

  // Connect to MetaMask
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.send("eth_requestAccounts", []);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(contractAddress, contractABI, signer);
        
        setProvider(provider);
        setAccount(accounts[0]);
        setContract(contract);

        // Check if user is owner
        const owner = await contract.owner();
        setIsOwner(accounts[0].toLowerCase() === owner.toLowerCase());

        // Check subscription status
        const subscriber = await contract.subscribers(accounts[0]);
        setIsSubscribed(subscriber.isActive);
        setStakedAmount(ethers.formatEther(subscriber.stakedAmount));

        return true;
      } catch (error) {
        console.error("Error connecting wallet:", error);
        return false;
      }
    } else {
      alert("Please install MetaMask!");
      return false;
    }
  };

  // Initialize
useEffect(() => {
  let mounted = true;
  
  // Store listeners in variables
  const handleAccountsChanged = (accounts) => {
    if (mounted) {
      // Handle account changes
    }
  };

  const handleChainChanged = () => {
    if (mounted) {
      window.location.reload();
    }
  };

  const init = async () => {
    try {
      if (window.ethereum) {
        await connectWallet();
        
        // Use the stored listener functions
        window.ethereum.on('accountsChanged', handleAccountsChanged);
        window.ethereum.on('chainChanged', handleChainChanged);
      }
    } catch (error) {
      console.error("Initialization error:", error);
    } finally {
      if (mounted) setLoading(false);
    }
  };

  init();

  return () => {
    mounted = false;
    
    // Remove using the same function references
    if (window.ethereum?.removeListener) {
      window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
      window.ethereum.removeListener('chainChanged', handleChainChanged);
    }
  };
}, [connectWallet]);// Make sure connectWallet is memoized or stable

    if (!account) {
      return (
        <div className="flex items-center justify-center h-screen">
          <button
            onClick={connectWallet}
            className="bg-blue-500 text-white px-4 py-2 rounded"
          >
            Connect Wallet
          </button>
        </div>
      );
    }
    

  return (
    <Web3Context.Provider value={{
      account,
      contract,
      provider,
      isOwner,
      isSubscribed,
      stakedAmount,
      connectWallet,
      loading
    }}>
      {children}
    </Web3Context.Provider>
  );
};

export const useWeb3 = () => useContext(Web3Context);