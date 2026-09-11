import { useQuery, useQueryClient } from '@tanstack/react-query';
import { executeSQL } from '../services/snowflake-api';

export function useSnowflakeQuery<T = any>(
  key: string,
  sql: string,
  options?: { enabled?: boolean; transform?: (data: any) => T }
) {
  return useQuery({
    queryKey: ['snowflake', key],
    queryFn: async () => {
      const result = await executeSQL(sql);
      if (options?.transform) return options.transform(result);
      return result;
    },
    enabled: options?.enabled !== false,
    staleTime: 30 * 60 * 1000,
    gcTime: 60 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
    refetchOnMount: false,
  });
}

export function useRefresh(key: string) {
  const qc = useQueryClient();
  return () => qc.invalidateQueries({ queryKey: ['snowflake', key] });
}

export function toObjects(result: { columns: { name: string }[]; data: string[][] }): Record<string, string>[] {
  if (!result?.columns || !result?.data) return [];
  return result.data.map((row) => {
    const obj: Record<string, string> = {};
    result.columns.forEach((col, i) => { obj[col.name] = row[i]; });
    return obj;
  });
}
