import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Web3Provider } from './contexts/Web3Context';
import Dashboard from './pages/Dashboard';
import Compaigns from './pages/Compaigns';
import CreateCompaignPage from './pages/CreateCompaignPage';
import CompaignDetailsPage from './pages/CompaignDetailsPage';
import Header1 from './components/Headers1';

function App() {
  return (
    <Web3Provider>
      <Router>
        <div className="min-h-screen bg-gray-50">
          <Header1 />
          <div className="container mx-auto px-4 py-6">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/compaigns" element={<Compaigns />} />
              <Route path="/create-compaign" element={<CreateCompaignPage />} />
              <Route path="/compaign/:id" element={<CompaignDetailsPage />} />
            </Routes>
          </div>
        </div>
      </Router>
    </Web3Provider>
  );
}

export default App;

