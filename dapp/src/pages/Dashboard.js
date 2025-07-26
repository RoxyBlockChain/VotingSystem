import React, { useState, useEffect } from 'react';
import { useWeb3 } from '../contexts/Web3Context';
import { useLocation } from 'react-router-dom';
import { ethers } from 'ethers';


import CompaignList from '../components/CompaignList';

const Dashboard = () => {
  const { contract, account, isSubscribed } = useWeb3();
  const [activeCompaigns, setActiveCompaigns] = useState([]);
  const [loading, setLoading] = useState(true);
  const web3 = useWeb3();
  const [stakedAmount, setStakedAmount] = useState(0);

  useEffect(() => {
    const loadCompaigns = async () => {
      if (!contract) return;

      try {
        const count = await contract.CompaignCount();
        const Compaigns = [];

        for (let i = 0; i < count; i++) {
          const Compaign = await contract.Compaigns(i);
          const status = await contract.getCompaignStatus(i);

          if (status === 'Active') {
            Compaigns.push({
              id: i,
              title: Compaign.title,
              startTime: new Date(Compaign.startTime * 1000),
              endTime: new Date(Compaign.endTime * 1000),
              status
            });
          }
        }

        setActiveCompaigns(Compaigns);
        setLoading(false);
      } catch (error) {
        console.error("Error loading Compaigns:", error);
        setLoading(false);
      }
    };

    loadCompaigns();
  }, [contract]);

  if (!account) {
    return (
      <div className="text-center py-12">
        <h2 className="text-2xl font-bold text-gray-800 mb-4">Connect Your Wallet</h2>
        <p className="text-gray-600 mb-6">
          To participate in decentralized voting, please connect your MetaMask wallet.
        </p>
        <button 
          onClick={web3.connectWallet}
          className="bg-indigo-600 text-white px-6 py-3 rounded-md font-medium hover:bg-indigo-700 transition"
        >
          Connect with MetaMask
        </button>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-800">Dashboard</h1>
        <p className="text-gray-600 mt-2">Welcome to the decentralized voting system</p>
      </div>

      {!isSubscribed ? (
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-xl font-bold text-gray-800 mb-4">Subscribe to Voting System</h2>
          <p className="text-gray-600 mb-6">
            To participate in voting Compaigns, you need to subscribe by staking at least 1 ETH/BNB. 
            Your personal information will be encrypted and stored securely.
          </p>
          {/* Subscription form would go here */}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-medium text-gray-900 mb-2">Your Voting Power</h3>
              <p className="text-3xl font-bold text-indigo-600">{stakedAmount} ETH</p>
              <p className="text-gray-600 mt-2">1 ETH = 1 Voting Power</p>
            </div>
            
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-medium text-gray-900 mb-2">Active Compaigns</h3>
              <p className="text-3xl font-bold text-indigo-600">{activeCompaigns.length}</p>
            </div>
            
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-medium text-gray-900 mb-2">Pending Rewards</h3>
              <p className="text-3xl font-bold text-indigo-600">0.00 ETH</p>
              <p className="text-gray-600 mt-2">Claim after voting ends</p>
            </div>
          </div>

          <div>
            <h2 className="text-xl font-bold text-gray-800 mb-4">Active Compaigns</h2>
            {loading ? (
              <p>Loading Compaigns...</p>
            ) : activeCompaigns.length > 0 ? (
              <CompaignList Compaigns={activeCompaigns} />
            ) : (
              <p>No active Compaigns at the moment.</p>
            )}
          </div>
        </>
      )}
    </div>
  );
};

export default Dashboard;