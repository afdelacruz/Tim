-- Tim Database Setup Script
-- Run this in your Railway PostgreSQL database

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS balance_snapshots CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  pin_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Connected accounts
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plaid_item_id VARCHAR(255) NOT NULL, -- Stores Plaid's item_id for managing the connection
  plaid_access_token VARCHAR(255) NOT NULL, -- Securely stored access token for Plaid API calls
  plaid_account_id VARCHAR(255) NOT NULL, -- Plaid's specific account_id
  account_name VARCHAR(255),
  account_type VARCHAR(50),
  institution_name VARCHAR(255),
  is_inflow BOOLEAN DEFAULT false,
  is_outflow BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  needs_reauthentication BOOLEAN DEFAULT false -- Flag for Plaid item errors
);

-- Balance snapshots (for tracking changes)
CREATE TABLE balance_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
  balance DECIMAL(12,2) NOT NULL,
  snapshot_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(account_id, snapshot_date)
);

-- Verify tables were created
\dt

-- Show table structures
\d users
\d accounts
\d balance_snapshots 