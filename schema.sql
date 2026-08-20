-- ============================================
-- 渠电作业CRM - Supabase Schema
-- 项目: channel-crm
-- 创建: 2026-08-10
-- ============================================

-- 1. 服务商表
CREATE TABLE IF NOT EXISTS crm_providers (
  id SERIAL PRIMARY KEY,
  provider_id TEXT UNIQUE NOT NULL,
  provider_name TEXT NOT NULL,
  provider_type TEXT,
  region TEXT,
  channel_manager TEXT,
  access_code TEXT UNIQUE NOT NULL,
  cities TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_providers_code ON crm_providers(access_code);
CREATE INDEX IF NOT EXISTS idx_crm_providers_region ON crm_providers(region);

-- 2. 员工表
CREATE TABLE IF NOT EXISTS crm_employees (
  id SERIAL PRIMARY KEY,
  employee_id TEXT UNIQUE,
  name TEXT NOT NULL,
  provider_id TEXT NOT NULL,
  role TEXT DEFAULT '小二',
  product TEXT,
  account_status TEXT,
  leave_time TIMESTAMPTZ,
  is_boss BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_employees_provider ON crm_employees(provider_id);

-- 3. 在约底池（PID维度）
CREATE TABLE IF NOT EXISTS crm_pids (
  id SERIAL PRIMARY KEY,
  pid TEXT NOT NULL,
  provider_id TEXT,
  city TEXT,
  district TEXT,
  store_name TEXT,
  category_l1 TEXT,
  category_l2 TEXT,
  category_l3 TEXT,
  dpv_30d NUMERIC DEFAULT 0,
  gmv_90d NUMERIC DEFAULT 0,
  tier TEXT,
  segment TEXT,
  store_count INT DEFAULT 1,
  is_signed_agent BOOLEAN DEFAULT FALSE,
  is_signed_eff BOOLEAN DEFAULT FALSE,
  is_signed_brand BOOLEAN DEFAULT FALSE,
  high_priority_cat BOOLEAN DEFAULT FALSE,
  data_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_pids_pid ON crm_pids(pid);
CREATE INDEX IF NOT EXISTS idx_crm_pids_provider ON crm_pids(provider_id);
CREATE INDEX IF NOT EXISTS idx_crm_pids_city ON crm_pids(city);
CREATE INDEX IF NOT EXISTS idx_crm_pids_tier ON crm_pids(tier);

-- 4. 门店表（PID下的门店明细）
CREATE TABLE IF NOT EXISTS crm_stores (
  id SERIAL PRIMARY KEY,
  pid TEXT NOT NULL,
  store_id TEXT,
  poi_id TEXT,
  store_name TEXT,
  city TEXT,
  district TEXT,
  address TEXT,
  category TEXT,
  dpv_30d NUMERIC DEFAULT 0,
  gmv_90d NUMERIC DEFAULT 0,
  is_ka BOOLEAN DEFAULT FALSE,
  is_chain BOOLEAN DEFAULT FALSE,
  data_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_stores_pid ON crm_stores(pid);
CREATE INDEX IF NOT EXISTS idx_crm_stores_city ON crm_stores(city);

-- 5. 未签约leads
CREATE TABLE IF NOT EXISTS crm_leads (
  id SERIAL PRIMARY KEY,
  poi_id TEXT,
  kb_shop_id TEXT,
  poi_name TEXT,
  city TEXT,
  district TEXT,
  category_l1 TEXT,
  category_l2 TEXT,
  category_l3 TEXT,
  brand_type TEXT,
  address TEXT,
  smoke_level TEXT,
  dpv_30d NUMERIC DEFAULT 0,
  is_high_priority BOOLEAN DEFAULT FALSE,
  provider_id TEXT,
  data_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_leads_poi ON crm_leads(poi_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_provider ON crm_leads(provider_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_city ON crm_leads(city);

-- 6. 跟进记录（商业化 + 开店通用）
CREATE TABLE IF NOT EXISTS crm_follow_ups (
  id SERIAL PRIMARY KEY,
  target_type TEXT NOT NULL CHECK (target_type IN ('pid','lead')),
  target_id TEXT NOT NULL,
  provider_id TEXT,
  employee_id TEXT,
  employee_name TEXT,
  status TEXT DEFAULT '待跟进',
  note TEXT,
  product_interest TEXT,
  intended_amount NUMERIC DEFAULT 0,
  next_action TEXT,
  next_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_followups_target ON crm_follow_ups(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_crm_followups_provider ON crm_follow_ups(provider_id);
CREATE INDEX IF NOT EXISTS idx_crm_followups_employee ON crm_follow_ups(employee_id);
CREATE INDEX IF NOT EXISTS idx_crm_followups_date ON crm_follow_ups(created_at);

-- 7. 占量记录（美食类目，顶展/钻展）
CREATE TABLE IF NOT EXISTS crm_occupancy (
  id SERIAL PRIMARY KEY,
  pid TEXT,
  order_name TEXT,
  city_name TEXT,
  adcode_chn TEXT,
  biz_code TEXT,
  biz_name TEXT,
  target_type TEXT,
  sale_plan_name TEXT,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  real_price NUMERIC DEFAULT 0,
  order_status TEXT,
  occupy_time TIMESTAMPTZ,
  data_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_occupancy_city ON crm_occupancy(city_name);
CREATE INDEX IF NOT EXISTS idx_crm_occupancy_biz ON crm_occupancy(biz_code);

-- 8. 每日作业汇总
CREATE TABLE IF NOT EXISTS crm_daily_summary (
  id SERIAL PRIMARY KEY,
  date DATE NOT NULL,
  provider_id TEXT,
  employee_id TEXT,
  level TEXT NOT NULL CHECK (level IN ('employee','provider','manager','region','national')),
  total_followups INT DEFAULT 0,
  new_followups INT DEFAULT 0,
  status_changes INT DEFAULT 0,
  signed_count INT DEFAULT 0,
  signed_amount NUMERIC DEFAULT 0,
  leads_contacted INT DEFAULT 0,
  leads_opened INT DEFAULT 0,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_crm_daily_date ON crm_daily_summary(date);
CREATE INDEX IF NOT EXISTS idx_crm_daily_provider ON crm_daily_summary(provider_id);
CREATE INDEX IF NOT EXISTS idx_crm_daily_level ON crm_daily_summary(level);

-- 9. 使用统计
CREATE TABLE IF NOT EXISTS crm_usage_logs (
  id SERIAL PRIMARY KEY,
  provider_id TEXT,
  provider_name TEXT,
  employee_id TEXT,
  employee_name TEXT,
  action TEXT,
  page TEXT,
  session_id TEXT,
  login_time TIMESTAMPTZ DEFAULT NOW(),
  duration_sec INT DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_crm_usage_provider ON crm_usage_logs(provider_id);
CREATE INDEX IF NOT EXISTS idx_crm_usage_date ON crm_usage_logs(login_time);

-- 10. 产品推荐映射（品类×DPV分层→推荐产品）
CREATE TABLE IF NOT EXISTS crm_recommendations (
  id SERIAL PRIMARY KEY,
  category TEXT,
  dpv_tier TEXT,
  store_scale TEXT,
  products TEXT[],
  pitch TEXT,
  value_prop TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. 案例库
CREATE TABLE IF NOT EXISTS crm_cases (
  id SERIAL PRIMARY KEY,
  title TEXT,
  city TEXT,
  category TEXT,
  product TEXT,
  before_desc TEXT,
  after_desc TEXT,
  metrics JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Row Level Security (RLS)
-- ============================================

ALTER TABLE crm_follow_ups ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_usage_logs DISABLE ROW LEVEL SECURITY;

-- 跟进记录：服务商只能看自己的
DROP POLICY IF EXISTS crm_followups_isolation ON crm_follow_ups;
CREATE POLICY crm_followups_isolation ON crm_follow_ups
  FOR ALL USING (provider_id = current_setting('app.current_provider_id', true));

-- 使用日志已关闭RLS，无需策略

-- ============================================
-- 管理员函数：批量导入数据
-- ============================================

CREATE OR REPLACE FUNCTION crm_upsert_pids(data JSONB)
RETURNS INT AS $$
DECLARE
  row_data JSONB;
  count INT := 0;
BEGIN
  FOR row_data IN SELECT * FROM jsonb_array_elements(data) LOOP
    INSERT INTO crm_pids (pid, provider_id, city, district, store_name, category_l1, category_l2, category_l3, dpv_30d, gmv_90d, tier, segment, store_count, is_signed_agent, is_signed_eff, is_signed_brand, high_priority_cat, data_version)
    VALUES (
      row_data->>'pid', row_data->>'provider_id', row_data->>'city', row_data->>'district',
      row_data->>'store_name', row_data->>'category_l1', row_data->>'category_l2', row_data->>'category_l3',
      (row_data->>'dpv_30d')::NUMERIC, (row_data->>'gmv_90d')::NUMERIC,
      row_data->>'tier', row_data->>'segment', (row_data->>'store_count')::INT,
      (row_data->>'is_signed_agent')::BOOLEAN, (row_data->>'is_signed_eff')::BOOLEAN,
      (row_data->>'is_signed_brand')::BOOLEAN, (row_data->>'high_priority_cat')::BOOLEAN,
      row_data->>'data_version'
    )
    ON CONFLICT (pid) DO UPDATE SET
      provider_id = EXCLUDED.provider_id, city = EXCLUDED.city, district = EXCLUDED.district,
      store_name = EXCLUDED.store_name, category_l1 = EXCLUDED.category_l1,
      dpv_30d = EXCLUDED.dpv_30d, gmv_90d = EXCLUDED.gmv_90d, tier = EXCLUDED.tier,
      segment = EXCLUDED.segment, data_version = EXCLUDED.data_version;
    count := count + 1;
  END LOOP;
  RETURN count;
END;
$$ LANGUAGE plpgsql;
