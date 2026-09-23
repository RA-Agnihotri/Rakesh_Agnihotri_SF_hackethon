export const SNOWFLAKE_CONFIG = {
  accountUrl: import.meta.env.VITE_SNOWFLAKE_ACCOUNT_URL || 'https://YOURORG-YOURACCOUNT.snowflakecomputing.com',
  warehouse: import.meta.env.VITE_SNOWFLAKE_WAREHOUSE || 'COMPUTE_WH',
  database: import.meta.env.VITE_SNOWFLAKE_DATABASE || 'INSURANCE_AI_HUB',
  schema: import.meta.env.VITE_SNOWFLAKE_SCHEMA || 'ANALYTICS',
  role: import.meta.env.VITE_SNOWFLAKE_ROLE || 'INSURANCE_SERVICE_ROLE',
  sessionTimeoutMs: 30 * 60 * 1000, // 30-minute inactivity timeout
};
