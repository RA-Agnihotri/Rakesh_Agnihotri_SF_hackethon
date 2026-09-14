import { useState, useMemo } from 'react';
import {
  BarChart, Bar, LineChart, Line, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts';
import { BarChart3, TrendingUp, PieChart as PieIcon, Table2 } from 'lucide-react';

export interface DataSet {
  columns: string[];
  types: string[];
  rows: string[][];
}

type ChartKind = 'bar' | 'line' | 'pie' | 'table';

const CHART_COLORS = [
  '#3b82f6', '#8b5cf6', '#22c55e', '#f59e0b', '#ef4444',
  '#06b6d4', '#ec4899', '#14b8a6', '#f97316', '#6366f1',
];

const DARK_BG = 'rgba(30,41,59,0.5)';

function isNumeric(val: string | null): boolean {
  if (val == null || val === '' || val === 'NULL') return false;
  return !isNaN(Number(val.replace(/[$,%]/g, '')));
}

function toNum(val: string | null): number {
  if (val == null || val === '' || val === 'NULL') return 0;
  return Number(val.replace(/[$,%]/g, '')) || 0;
}

function isDateLike(colName: string): boolean {
  const n = colName.toUpperCase();
  return /DATE|TIME|MONTH|YEAR|QUARTER|WEEK|DAY|PERIOD/.test(n);
}

function detectChart(ds: DataSet): ChartKind {
  if (ds.rows.length === 0 || ds.columns.length < 2) return 'table';

  const numericCols: number[] = [];
  const catCols: number[] = [];
  const dateCols: number[] = [];

  ds.columns.forEach((col, i) => {
    const sampleVals = ds.rows.slice(0, 10).map(r => r[i]);
    const numCount = sampleVals.filter(v => isNumeric(v)).length;

    if (isDateLike(col)) {
      dateCols.push(i);
    } else if (numCount >= sampleVals.length * 0.7) {
      numericCols.push(i);
    } else {
      catCols.push(i);
    }
  });

  if (dateCols.length > 0 && numericCols.length > 0) return 'line';
  if (ds.rows.length <= 8 && numericCols.length === 1 && catCols.length === 1) return 'pie';
  if (catCols.length >= 1 && numericCols.length >= 1) return 'bar';
  return 'table';
}

function buildChartData(ds: DataSet) {
  const numericCols: number[] = [];
  const catCols: number[] = [];
  const dateCols: number[] = [];

  ds.columns.forEach((col, i) => {
    const sampleVals = ds.rows.slice(0, 10).map(r => r[i]);
    const numCount = sampleVals.filter(v => isNumeric(v)).length;
    if (isDateLike(col)) dateCols.push(i);
    else if (numCount >= sampleVals.length * 0.7) numericCols.push(i);
    else catCols.push(i);
  });

  const labelIdx = dateCols[0] ?? catCols[0] ?? 0;
  const valueIdxs = numericCols.length > 0 ? numericCols : [1];

  const data = ds.rows.map(row => {
    const point: Record<string, any> = { label: row[labelIdx] ?? '' };
    valueIdxs.forEach(vi => {
      point[ds.columns[vi]] = toNum(row[vi]);
    });
    return point;
  });

  return { data, labelKey: 'label', valueKeys: valueIdxs.map(vi => ds.columns[vi]) };
}

const CHART_ICONS: Record<ChartKind, typeof BarChart3> = {
  bar: BarChart3, line: TrendingUp, pie: PieIcon, table: Table2,
};

export default function DataVisualizer({ dataset, accentColor }: { dataset: DataSet; accentColor?: string }) {
  const defaultKind = useMemo(() => detectChart(dataset), [dataset]);
  const [kind, setKind] = useState<ChartKind>(defaultKind);
  const { data, labelKey, valueKeys } = useMemo(() => buildChartData(dataset), [dataset]);

  const available: ChartKind[] = ['bar', 'line', 'pie', 'table'];

  if (dataset.rows.length === 0) {
    return <p className="text-xs text-gray-400 italic">No data returned.</p>;
  }

  return (
    <div className="mt-2 rounded-lg border border-gray-200 dark:border-slate-600 overflow-hidden bg-white dark:bg-slate-800">
      {/* Toolbar */}
      <div className="flex items-center gap-1 px-2 py-1.5 border-b border-gray-100 dark:border-slate-700 bg-gray-50 dark:bg-slate-700/50">
        {available.map(k => {
          const Icon = CHART_ICONS[k];
          return (
            <button
              key={k}
              onClick={() => setKind(k)}
              className={`flex items-center gap-1 px-2 py-1 rounded text-[10px] font-medium transition-colors ${
                kind === k
                  ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400'
                  : 'text-gray-500 hover:bg-gray-100 dark:hover:bg-slate-600 dark:text-slate-400'
              }`}
            >
              <Icon className="w-3 h-3" />
              {k.charAt(0).toUpperCase() + k.slice(1)}
            </button>
          );
        })}
        <span className="ml-auto text-[9px] text-gray-400 dark:text-slate-500">
          {dataset.rows.length} row{dataset.rows.length !== 1 ? 's' : ''}
        </span>
      </div>

      {/* Chart / Table */}
      <div className="p-3">
        {kind === 'bar' && (
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={data} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,0.2)" />
              <XAxis dataKey={labelKey} tick={{ fontSize: 10 }} interval={0} angle={data.length > 6 ? -35 : 0} textAnchor={data.length > 6 ? 'end' : 'middle'} height={data.length > 6 ? 60 : 30} />
              <YAxis tick={{ fontSize: 10 }} width={55} tickFormatter={(v: number) => v >= 1000000 ? `${(v / 1000000).toFixed(1)}M` : v >= 1000 ? `${(v / 1000).toFixed(0)}K` : String(v)} />
              <Tooltip contentStyle={{ fontSize: 11, background: DARK_BG, border: 'none', borderRadius: 8 }} />
              {valueKeys.length > 1 && <Legend wrapperStyle={{ fontSize: 10 }} />}
              {valueKeys.map((vk, i) => (
                <Bar key={vk} dataKey={vk} fill={accentColor || CHART_COLORS[i % CHART_COLORS.length]} radius={[4, 4, 0, 0]} />
              ))}
            </BarChart>
          </ResponsiveContainer>
        )}

        {kind === 'line' && (
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={data} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,0.2)" />
              <XAxis dataKey={labelKey} tick={{ fontSize: 10 }} />
              <YAxis tick={{ fontSize: 10 }} width={55} tickFormatter={(v: number) => v >= 1000000 ? `${(v / 1000000).toFixed(1)}M` : v >= 1000 ? `${(v / 1000).toFixed(0)}K` : String(v)} />
              <Tooltip contentStyle={{ fontSize: 11, background: DARK_BG, border: 'none', borderRadius: 8 }} />
              {valueKeys.length > 1 && <Legend wrapperStyle={{ fontSize: 10 }} />}
              {valueKeys.map((vk, i) => (
                <Line key={vk} type="monotone" dataKey={vk} stroke={accentColor || CHART_COLORS[i % CHART_COLORS.length]} strokeWidth={2} dot={{ r: 3 }} activeDot={{ r: 5 }} />
              ))}
            </LineChart>
          </ResponsiveContainer>
        )}

        {kind === 'pie' && (
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie
                data={data}
                dataKey={valueKeys[0]}
                nameKey={labelKey}
                cx="50%"
                cy="50%"
                outerRadius={80}
                label={({ name, percent }: any) => `${name} ${(percent * 100).toFixed(0)}%`}
                labelLine={{ strokeWidth: 1 }}
              >
                {data.map((_, i) => (
                  <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip contentStyle={{ fontSize: 11, background: DARK_BG, border: 'none', borderRadius: 8 }} />
            </PieChart>
          </ResponsiveContainer>
        )}

        {kind === 'table' && (
          <div className="overflow-x-auto max-h-[260px] overflow-y-auto">
            <table className="w-full text-[10px]">
              <thead className="sticky top-0">
                <tr className="bg-gray-50 dark:bg-slate-700">
                  {dataset.columns.map(col => (
                    <th key={col} className="px-2 py-1.5 text-left font-semibold text-gray-600 dark:text-slate-300 whitespace-nowrap border-b border-gray-200 dark:border-slate-600">
                      {col}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {dataset.rows.slice(0, 50).map((row, ri) => (
                  <tr key={ri} className={ri % 2 === 0 ? '' : 'bg-gray-50/50 dark:bg-slate-700/30'}>
                    {row.map((val, ci) => (
                      <td key={ci} className="px-2 py-1 text-gray-700 dark:text-slate-300 whitespace-nowrap border-b border-gray-100 dark:border-slate-700">
                        {val ?? 'NULL'}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
            {dataset.rows.length > 50 && (
              <p className="text-[9px] text-gray-400 mt-1 text-center">Showing 50 of {dataset.rows.length} rows</p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
