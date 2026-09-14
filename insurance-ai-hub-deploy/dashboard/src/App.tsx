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
import MarketIntelAgent from './pages/MarketIntelAgent';
import PricingAdvisorAgent from './pages/PricingAdvisorAgent';
import ProductMatcherAgent from './pages/ProductMatcherAgent';
import EnterpriseHubAgent from './pages/EnterpriseHubAgent';
import { getToken, setToken } from './services/snowflake-api';
import { prefetchAllDashboardData } from './services/prefetch';
import { useThemeStore } from './stores';

export default function App() {
  const [authenticated, setAuthenticated] = useState(false);
  const [checking, setChecking] = useState(true);
  const queryClient = useQueryClient();
  const setDark = useThemeStore((s) => s.setDark);

  useEffect(() => {
    const saved = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    setDark(saved === 'dark' || (!saved && prefersDark));
  }, []);

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
        <Route path="/market-intel" element={<MarketIntelAgent />} />
        <Route path="/pricing-advisor" element={<PricingAdvisorAgent />} />
        <Route path="/product-matcher" element={<ProductMatcherAgent />} />
        <Route path="/enterprise-hub" element={<EnterpriseHubAgent />} />
      </Routes>
    </Layout>
  );
}
