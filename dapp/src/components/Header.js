import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useWeb3 } from '../contexts/Web3Context';


const Header = () => {
  const { account, isConnected, connectWallet, isOwner, isSubscribed, stakedAmount } = useWeb3();
  const location = useLocation();

  const isActive = (path) => {
    return location.pathname === path;
  };

  return (
    <header className="bg-white shadow-md">
      <div className="container mx-auto px-4">
        <div className="flex justify-between items-center py-4">
          <div className="flex items-center space-x-8">
            <Link to="/" className="text-2xl font-bold text-indigo-600">VotingSystem</Link>
            <nav className="hidden md:flex space-x-6">
              <Link to="/" className={`py-2 font-medium ${isActive('/') ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-gray-600 hover:text-gray-900'}`}>
                Dashboard
              </Link>
              <Link to="/campaigns" className={`py-2 font-medium ${isActive('/campaigns') ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-gray-600 hover:text-gray-900'}`}>
                Campaigns
              </Link>
              {isOwner && (
                <Link to="/create-campaign" className={`py-2 font-medium ${isActive('/create-campaign') ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-gray-600 hover:text-gray-900'}`}>
                  Create Campaign
                </Link>
              )}
            </nav>
          </div>

          <div className="flex items-center space-x-4">
            {isSubscribed && (
              <div className="hidden md:flex items-center bg-green-100 text-green-800 px-4 py-2 rounded-full">
                <span className="font-medium">{stakedAmount} ETH</span>
              </div>
            )}

            {account ? (
              <div className="bg-indigo-600 text-white px-4 py-2 rounded-full">
                {account.substring(0, 6)}...{account.substring(account.length - 4)}
              </div>
            ) : (
              <button 
                onClick={connectWallet}
                className="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition"
              >
                Connect Wallet
              </button>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;