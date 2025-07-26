import React from 'react';
import { Link } from 'react-router-dom';

const CompaignList = ({ Compaigns }) => {
  const formatDate = (date) => {
    return date.toLocaleString();
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {Compaigns.map(Compaign => (
        <div key={Compaign.id} className="bg-white rounded-lg shadow-md overflow-hidden">
          <div className="p-6">
            <div className="flex justify-between items-start">
              <h3 className="text-lg font-bold text-gray-900">{Compaign.title}</h3>
              <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full">
                {Compaign.status}
              </span>
            </div>
            
            <div className="mt-4 text-sm text-gray-600">
              <div className="flex items-center mb-1">
                <span>Start: {formatDate(Compaign.startTime)}</span>
              </div>
              <div className="flex items-center">
                <span>End: {formatDate(Compaign.endTime)}</span>
              </div>
            </div>
            
            <div className="mt-6">
              <Link 
                to={`/Compaign/${Compaign.id}`}
                className="w-full bg-indigo-600 text-white py-2 rounded-md text-sm font-medium hover:bg-indigo-700 transition block text-center"
              >
                View Compaign
              </Link>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default CompaignList;