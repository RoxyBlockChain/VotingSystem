import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useWeb3 } from '../contexts/Web3Context';
import { ethers } from 'ethers';

const CompaignDetailsPage = () => {
  const { id } = useParams();
  const { contract, account, isSubscribed } = useWeb3();
  const [Compaign, setCompaign] = useState(null);
  const [options, setOptions] = useState([]);
  const [status, setStatus] = useState('');
  const [selectedOption, setSelectedOption] = useState(null);
  const [hasVoted, setHasVoted] = useState(false);
  const [votes, setVotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [voting, setVoting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    const loadCompaign = async () => {
      if (!contract) return;

      try {
        // Load Compaign details
        const CompaignData = await contract.Compaigns(id);
        const options = await contract.getCompaignOptions(id);
        const status = await contract.getCompaignStatus(id);
        const hasVoted = await contract.hasVoted(id, account);
        
        // Load votes for each option
        const votesPromises = options.map((_, index) => 
          contract.getVotes(id, index)
        );
        const votes = await Promise.all(votesPromises);
        
        setCompaign({
          id: id,
          title: CompaignData.title,
          startTime: new Date(CompaignData.startTime * 1000),
          endTime: new Date(CompaignData.endTime * 1000),
          resultsPublished: CompaignData.resultsPublished,
          winningOption: CompaignData.winningOption
        });
        
        setOptions(options);
        setStatus(status);
        setHasVoted(hasVoted);
        setVotes(votes.map(vote => ethers.formatEther(vote)));
        setLoading(false);
      } catch (error) {
        console.error("Error loading Compaign:", error);
        setLoading(false);
      }
    };

    loadCompaign();
  }, [contract, id, account]);

  const handleVote = async () => {
    if (!selectedOption && selectedOption !== 0) {
      setError('Please select an option to vote for');
      return;
    }

    setVoting(true);
    setError('');

    try {
      // First acknowledge notification (in a real app, you would have handled this earlier)
      // Then vote
      const tx = await contract.vote(id, selectedOption);
      await tx.wait();
      setHasVoted(true);
    } catch (error) {
      console.error("Error voting:", error);
      setError('Failed to vote. Please try again.');
    } finally {
      setVoting(false);
    }
  };

  if (loading) {
    return <p>Loading Compaign details...</p>;
  }

  if (!Compaign) {
    return <p>Compaign not found</p>;
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-white p-6 rounded-lg shadow-md">
        <h1 className="text-3xl font-bold text-gray-800 mb-2">{Compaign.title}</h1>
        
        <div className="flex flex-wrap gap-4 mb-6">
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${
            status === 'Active' ? 'bg-green-100 text-green-800' :
            status.includes('Completed') ? 'bg-blue-100 text-blue-800' :
            'bg-yellow-100 text-yellow-800'
          }`}>
            {status}
          </span>
          <span className="text-gray-600">
            Start: {Compaign.startTime.toLocaleString()}
          </span>
          <span className="text-gray-600">
            End: {Compaign.endTime.toLocaleString()}
          </span>
        </div>

        {Compaign.resultsPublished && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
            <h3 className="text-lg font-medium text-blue-800 mb-2">Voting Results</h3>
            <p className="text-blue-700">
              Winning Option: {options[Compaign.winningOption]}
            </p>
          </div>
        )}

        <h2 className="text-xl font-bold text-gray-800 mb-4">Voting Options</h2>
        <div className="space-y-4 mb-6">
          {options.map((option, index) => (
            <div key={index} className="p-4 border border-gray-200 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center">
                  <input
                    type="radio"
                    id={`option-${index}`}
                    name="voting-option"
                    value={index}
                    checked={selectedOption === index}
                    onChange={() => setSelectedOption(index)}
                    disabled={hasVoted || status !== 'Active' || !isSubscribed}
                    className="h-5 w-5 text-indigo-600"
                  />
                  <label htmlFor={`option-${index}`} className="ml-3 font-medium text-gray-700">
                    {option}
                  </label>
                </div>
                <span className="bg-gray-100 text-gray-800 px-3 py-1 rounded-full text-sm">
                  {votes[index]} votes
                </span>
              </div>
              {votes[index] > 0 && (
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-indigo-600 h-2 rounded-full" 
                    style={{ width: `${(votes[index] / Math.max(1, votes.reduce((a, b) => parseFloat(a) + parseFloat(b), 0)) * 100)}%` }}
                  ></div>
                </div>
              )}
            </div>
          ))}
        </div>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}

        {status === 'Active' && isSubscribed && !hasVoted && (
          <button
            onClick={handleVote}
            disabled={voting}
            className="bg-indigo-600 text-white px-6 py-3 rounded-md font-medium hover:bg-indigo-700 transition"
          >
            {voting ? 'Processing...' : 'Submit Vote'}
          </button>
        )}

        {hasVoted && (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
            You have already voted in this Compaign.
          </div>
        )}

        {!isSubscribed && status === 'Active' && (
          <div className="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded">
            You must subscribe to participate in voting.
          </div>
        )}
      </div>
    </div>
  );
};

export default CompaignDetailsPage;