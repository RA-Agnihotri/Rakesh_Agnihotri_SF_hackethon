import { useState, useEffect } from 'react';
import { Routes, Route } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import Layout from './components/layout/Layout';
import Login from './pages/Login';
import ExecutiveDashboard from './pages/ExecutiveDashboard';
import KPIDashboard from './pages/KPIDashboard';
import AIAssistant from './pages/AIAssistant';
import KnowledgeHub from './pages/KnowledgeHub';
import AgentInsights from './pages/AgentInsights';
import DocumentIntelligence from './pages/DocumentIntelligence';
import DataExplorer from './pages/DataExplorer';
import GovernanceDashboard from './pages/GovernanceDashboard';
import AdminConsole from './pages/AdminConsole';
import { getToken, setToken } from './services/snowflake-api';
import { prefetchAllDashboardData } from './services/prefetch';

export default function App() {
  const [authenticated, setAuthenticated] = useState(false);
  const [checking, setChecking] = useState(true);
  const queryClient = useQueryClient();

  useEffect(() => {
    const envPat = import.meta.env.VITE_SNOWFLAKE_PAT;
    if (envPat && envPat !== 'paste-your-pat-token-here') {
      setToken(envPat);
      setAuthenticated(true);
      prefetchAllDashboardData(queryClient);
    } else if (getToken()) {
      setAuthenticated(true);
    }
    setChecking(false);
  }, []);

  const handleLogin = () => {
    setAuthenticated(true);
    prefetchAllDashboardData(queryClient);
  };

  if (checking) return null;
  if (!authenticated) return <Login onLogin={handleLogin} />;

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<ExecutiveDashboard />} />
        <Route path="/kpi" element={<KPIDashboard />} />
        <Route path="/assistant" element={<AIAssistant />} />
        <Route path="/knowledge" element={<KnowledgeHub />} />
        <Route path="/agents" element={<AgentInsights />} />
        <Route path="/documents" element={<DocumentIntelligence />} />
        <Route path="/explorer" element={<DataExplorer />} />
        <Route path="/governance" element={<GovernanceDashboard />} />
        <Route path="/admin" element={<AdminConsole />} />
      </Routes>
    </Layout>
  );
}
