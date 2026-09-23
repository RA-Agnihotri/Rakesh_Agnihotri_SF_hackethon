import { useState, useEffect, useCallback, useRef } from 'react';
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
import { getToken, clearToken } from './services/snowflake-api';
import { prefetchAllDashboardData } from './services/prefetch';
import { useThemeStore } from './stores';
import { SNOWFLAKE_CONFIG } from './lib/constants';

export default function App() {
  const [authenticated, setAuthenticated] = useState(false);
  const [checking, setChecking] = useState(true);
  const queryClient = useQueryClient();
  const setDark = useThemeStore((s) => s.setDark);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const saved = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    setDark(saved === 'dark' || (!saved && prefersDark));
  }, []);

  // Session timeout: log out after 30 minutes of inactivity
  const resetTimeout = useCallback(() => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    if (!authenticated) return;
    timeoutRef.current = setTimeout(() => {
      clearToken();
      setAuthenticated(false);
    }, SNOWFLAKE_CONFIG.sessionTimeoutMs);
  }, [authenticated]);

  useEffect(() => {
    if (!authenticated) return;
    const events = ['mousedown', 'keydown', 'scroll', 'touchstart'];
    events.forEach(e => window.addEventListener(e, resetTimeout));
    resetTimeout();
    return () => {
      events.forEach(e => window.removeEventListener(e, resetTimeout));
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, [authenticated, resetTimeout]);

  useEffect(() => {
    // Runtime-only auth: check if a token was already set (e.g. from Login page)
    // SECURITY: No build-time PAT — tokens must be entered at runtime via the Login UI.
    if (getToken()) {
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
