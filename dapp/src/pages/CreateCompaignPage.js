import React, { useState } from 'react';
import { useWeb3 } from '../contexts/Web3Context';

const CreateCompaignPage = () => {
  const { contract, isOwner } = useWeb3();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [options, setOptions] = useState(['', '']);
  const [startTime, setStartTime] = useState('');
  const [duration, setDuration] = useState(24);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleOptionChange = (index, value) => {
    const newOptions = [...options];
    newOptions[index] = value;
    setOptions(newOptions);
  };

  const addOption = () => {
    setOptions([...options, '']);
  };

  const removeOption = (index) => {
    if (options.length > 2) {
      const newOptions = [...options];
      newOptions.splice(index, 1);
      setOptions(newOptions);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Convert start time to timestamp
      const startTimestamp = Math.floor(new Date(startTime).getTime() / 1000);
      
      // Filter out empty options
      const validOptions = options.filter(option => option.trim() !== '');

      // Call contract
      const tx = await contract.launchCompaign(
        title,
        validOptions,
        startTimestamp,
        duration
      );

      await tx.wait();
      setSuccess(true);
      setTitle('');
      setDescription('');
      setOptions(['', '']);
      setStartTime('');
      setDuration(24);
    } catch (error) {
      console.error("Error creating campaign:", error);
    } finally {
      setLoading(false);
    }
  };

  if (!isOwner) {
    return (
      <div className="text-center py-12">
        <h2 className="text-2xl font-bold text-gray-800 mb-4">Access Restricted</h2>
        <p className="text-gray-600">
          Only the contract owner can create new voting campaigns.
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto">
      <h1 className="text-3xl font-bold text-gray-800 mb-6">Create New Campaign</h1>
      
      {success && (
        <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
          Campaign created successfully!
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow-md">
        <div className="mb-4">
          <label className="block text-gray-700 font-medium mb-2">Campaign Title</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
            required
          />
        </div>

        <div className="mb-4">
          <label className="block text-gray-700 font-medium mb-2">Description (Optional)</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
            rows="3"
          ></textarea>
        </div>

        <div className="mb-4">
          <label className="block text-gray-700 font-medium mb-2">Voting Options</label>
          {options.map((option, index) => (
            <div key={index} className="flex mb-2">
              <input
                type="text"
                value={option}
                onChange={(e) => handleOptionChange(index, e.target.value)}
                className="flex-grow px-3 py-2 border border-gray-300 rounded-md"
                required
              />
              {options.length > 2 && (
                <button
                  type="button"
                  onClick={() => removeOption(index)}
                  className="ml-2 px-3 py-2 bg-red-600 text-white rounded-md"
                >
                  Remove
                </button>
              )}
            </div>
          ))}
          <button
            type="button"
            onClick={addOption}
            className="mt-2 px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300"
          >
            Add Option
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-gray-700 font-medium mb-2">Start Time</label>
            <input
              type="datetime-local"
              value={startTime}
              onChange={(e) => setStartTime(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            />
          </div>
          <div>
            <label className="block text-gray-700 font-medium mb-2">Duration (hours)</label>
            <input
              type="number"
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
              min="1"
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-indigo-600 text-white py-2 rounded-md font-medium hover:bg-indigo-700 transition"
        >
          {loading ? 'Creating Compaign...' : 'Launch Compaign'}
        </button>
      </form>
    </div>
  );
};

export default CreateCompaignPage;