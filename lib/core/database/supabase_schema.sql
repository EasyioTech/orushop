-- Supabase schema for RetailDost backup and sync

-- User backups table
CREATE TABLE IF NOT EXISTS user_backups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  backup_file_path TEXT NOT NULL,
  backup_size_bytes INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  restored_at TIMESTAMP,
  status TEXT DEFAULT 'completed' -- completed, failed, pending
);

CREATE INDEX IF NOT EXISTS idx_user_backups_user_id ON user_backups(user_id);
CREATE INDEX IF NOT EXISTS idx_user_backups_created_at ON user_backups(created_at DESC);

-- Sales sync log
CREATE TABLE IF NOT EXISTS sales_sync (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  sale_id INTEGER NOT NULL,
  final_amount DECIMAL(10, 2),
  payment_method TEXT,
  created_at TIMESTAMP,
  synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, sale_id)
);

CREATE INDEX IF NOT EXISTS idx_sales_sync_user_id ON sales_sync(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_sync_synced_at ON sales_sync(synced_at DESC);

-- Health check table (for connectivity testing)
CREATE TABLE IF NOT EXISTS health_check (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
