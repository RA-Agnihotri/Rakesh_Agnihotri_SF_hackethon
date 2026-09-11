import { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { Activity, LayoutDashboard, BarChart3, Bot, BookOpen, Users, FileText, Database, Shield, Settings, ChevronLeft, ChevronRight } from 'lucide-react';

const NAV_ITEMS = [
  { to: '/', icon: LayoutDashboard, label: 'Executive' },
  { to: '/kpi', icon: BarChart3, label: 'KPI Dashboard' },
  { to: '/assistant', icon: Bot, label: 'AI Assistant' },
  { to: '/knowledge', icon: BookOpen, label: 'Knowledge Hub' },
  { to: '/agents', icon: Users, label: 'Agent Insights' },
  { to: '/documents', icon: FileText, label: 'Documents' },
  { to: '/explorer', icon: Database, label: 'Data Explorer' },
  { to: '/governance', icon: Shield, label: 'Governance' },
  { to: '/admin', icon: Settings, label: 'Admin' },
];

export default function Layout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-slate-900">
      <aside className={`${collapsed ? 'w-16' : 'w-56'} flex-shrink-0 bg-white dark:bg-slate-800 border-r border-gray-200 dark:border-slate-700 flex flex-col transition-all duration-200`}>
        <div className="flex items-center gap-2 px-4 py-4 border-b border-gray-200 dark:border-slate-700">
          <Activity className="w-6 h-6 text-brand-600 flex-shrink-0" />
          {!collapsed && <span className="font-bold text-sm text-gray-900 dark:text-white truncate">Insurance Intelligence</span>}
        </div>
        <nav className="flex-1 py-2 space-y-0.5 overflow-y-auto">
          {NAV_ITEMS.map(({ to, icon: Icon, label }) => (
            <NavLink key={to} to={to} end={to === '/'}
              className={({ isActive }) => `flex items-center gap-3 px-4 py-2.5 text-sm font-medium transition-colors ${
                isActive
                  ? 'text-brand-600 bg-brand-50 dark:bg-brand-900/20 border-r-2 border-brand-600'
                  : 'text-gray-600 dark:text-slate-400 hover:bg-gray-50 dark:hover:bg-slate-700'
              }`}>
              <Icon className="w-4 h-4 flex-shrink-0" />
              {!collapsed && <span className="truncate">{label}</span>}
            </NavLink>
          ))}
        </nav>
        <button onClick={() => setCollapsed(!collapsed)} className="p-3 border-t border-gray-200 dark:border-slate-700 text-gray-400 hover:text-gray-600">
          {collapsed ? <ChevronRight className="w-4 h-4 mx-auto" /> : <ChevronLeft className="w-4 h-4 mx-auto" />}
        </button>
      </aside>
      <main className="flex-1 overflow-y-auto p-6">{children}</main>
    </div>
  );
}
