-- =========================================================================
-- PROJECT: Construction ERP Job-Costing Data Sandbox
-- DEVELOPER: Chaitanya Yarlagadda
-- SEQUENCE LOG: Created September 13, 2026
-- =========================================================================

-- PHASE 1: Relational Schema Architecture Setup
-- -------------------------------------------------------------------------
-- Track 1: The Project Estimates (Job Costing Baseline Rules)
CREATE TABLE erp_job_estimates (
    job_id VARCHAR(10) NOT NULL,
    cost_code VARCHAR(10) NOT NULL,
    description VARCHAR(50),
    budgeted_amount DECIMAL(10,2),
    PRIMARY KEY (job_id, cost_code)
);

-- Track 2: Field Service Labor Logs (Crew Timecards from Trucks)
CREATE TABLE field_labor_logs (
    timecard_id INTEGER PRIMARY KEY AUTOINCREMENT,
    date_worked DATE,
    job_id VARCHAR(10),
    cost_code VARCHAR(10),
    crew_leader VARCHAR(30),
    hours_worked INT,
    hourly_rate DECIMAL(10,2),
    entry_type VARCHAR(10) NOT NULL DEFAULT 'DAILY'
        CHECK (entry_type IN ('DAILY', 'WEEKLY'))  -- what the hours figure represents
);

-- Track 3: Material Purchasing Invoices (Accounts Payable Supply Records)
CREATE TABLE vendor_material_invoices (
    invoice_id VARCHAR(10) PRIMARY KEY,
    job_id VARCHAR(10),
    cost_code VARCHAR(10),
    vendor_name VARCHAR(50),
    item_description VARCHAR(50),
    actual_cost DECIMAL(10,2)
);


-- PHASE 2: Operational Data Ingestion
-- -------------------------------------------------------------------------
-- Injecting Baseline Cost Rules for a Commercial Project (Job #91381)
INSERT INTO erp_job_estimates VALUES ('91381', '02-300', 'Irrigation & Pipe Installation', 12000.00);
INSERT INTO erp_job_estimates VALUES ('91381', '02-500', 'Commercial Oak Tree Planting', 30000.00);

-- Loading Baseline Crew Timecard Log Entries
-- Weekly logs are dated by week-ending date (Friday).
INSERT INTO field_labor_logs (date_worked, job_id, cost_code, crew_leader, hours_worked, hourly_rate, entry_type) 
VALUES ('2026-09-04', '91381', '02-300', 'Martinez_J', 40, 45.00, 'WEEKLY'),  -- Week ending 09/04
       ('2026-09-11', '91381', '02-300', 'Martinez_J', 40, 45.00, 'WEEKLY'),  -- Week ending 09/11
       ('2026-09-11', '91381', '02-500', 'Hernandez_R', 35, 50.00, 'WEEKLY'); -- Week ending 09/11

-- Loading Supply Chain Nursery Invoices
INSERT INTO vendor_material_invoices VALUES 
('INV-1001', '91381', '02-500', 'Valley Nursery Supply', '200 Boxed Live Oak Trees', 28500.00),
('INV-1002', '91381', '02-500', 'Pacific Coast Turf', 'Additional Soil Deliveries', 4200.00);


-- PHASE 3: Data Governance Validation & Logic Iteration Sequence
-- -------------------------------------------------------------------------
-- MY DEVELOPMENT SEQUENCE NOTE:
-- I initially built a rule checking for single-day shift entry typos: "hours_worked > 16".
-- However, because my test dataset contained weekly running log values (40, 40, 35),
-- my strict single-shift rule unexpectedly flagged those valid rows as exceptions.
-- The rule was not the problem; my assumption about what the number meant was.
-- A 40-hour week is not a 40-hour day, and the table had no way to say which one
-- a row was. The fix has two parts:
--   1. An entry_type column (DAILY / WEEKLY) so each row records what its hours represent.
--   2. A view that applies the threshold that matches the entry type.
-- Thresholds are my own judgment, written down so they can be argued with:
--   DAILY  > 16 hours  -> flagged as a likely single-shift typo
--   WEEKLY > 80 hours  -> flagged as an implausible weekly total
--   Any entry of zero or less -> flagged regardless of type

-- Injecting Active Human Entry Anomalies to test the validation engine
INSERT INTO field_labor_logs (date_worked, job_id, cost_code, crew_leader, hours_worked, hourly_rate, entry_type) 
VALUES ('2026-09-13', '91381', '02-300', 'Unknown_Entry', -5, 45.00, 'DAILY'), -- Should be trapped: negative hours
       ('2026-09-15', '91381', '02-300', 'Smith_T', 24, 45.00, 'DAILY');       -- Should be trapped: 24h single shift

-- Compiling the Final Dynamic Exception Audit View
CREATE VIEW erp_data_exceptions_audit AS
SELECT 
    timecard_id,
    job_id,
    cost_code,
    entry_type,
    hours_worked,
    CASE 
        WHEN hours_worked <= 0 THEN 'ERROR: Zero or Negative Hours Entered'
        WHEN entry_type = 'DAILY'  AND hours_worked > 16 THEN 'ERROR: Over 16 Hours in a Single Shift'
        WHEN entry_type = 'WEEKLY' AND hours_worked > 80 THEN 'ERROR: Over 80 Hours in a Single Week'
    END AS error_description
FROM field_labor_logs
WHERE hours_worked <= 0
   OR (entry_type = 'DAILY'  AND hours_worked > 16)
   OR (entry_type = 'WEEKLY' AND hours_worked > 80);

-- PHASE 4: Core Analytics Reporting Output
-- -------------------------------------------------------------------------
-- Query to extract and verify all active anomalies trapped by the audit view:
-- SELECT * FROM erp_data_exceptions_audit;
--
-- Expected result: exactly 2 rows (timecard 4: -5 hours; timecard 5: 24-hour shift).
-- The three weekly logs (40, 40, 35) must NOT appear.
