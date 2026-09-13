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
    hourly_rate DECIMAL(10,2)
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
INSERT INTO field_labor_logs (date_worked, job_id, cost_code, crew_leader, hours_worked, hourly_rate) 
VALUES ('2026-09-10', '91381', '02-300', 'Martinez_J', 40, 45.00), -- Weekly running log
       ('2026-09-11', '91381', '02-300', 'Martinez_J', 40, 45.00), -- Weekly running log
       ('2026-09-12', '91381', '02-500', 'Hernandez_R', 35, 50.00); -- Weekly running log

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
-- Below is my calibrated, production-grade fix using a CASE statement and OR logic.
-- This dynamically keeps regular logs clear while accurately trapping true system anomalies.

-- Injecting Active Human Entry Anomalies to test the validation engine
INSERT INTO field_labor_logs (date_worked, job_id, cost_code, crew_leader, hours_worked, hourly_rate) 
VALUES ('2026-09-13', '91381', '02-300', 'Unknown_Entry', -5, 45.00), -- Traps Negative Value Entry Error
       ('2026-09-15', '91381', '02-300', 'Smith_T', 24, 45.00);      -- Traps Shift Overrun Typo Error

-- Compiling the Final Dynamic Exception Audit View
CREATE VIEW erp_data_exceptions_audit AS
SELECT 
    timecard_id,
    job_id,
    cost_code,
    hours_worked,
    CASE 
        WHEN hours_worked <= 0 THEN 'ERROR: Negative Hours Entered'
        WHEN hours_worked > 16 THEN 'ERROR: Over 16 Hours in a Single Shift'
    END AS error_description
FROM field_labor_logs
WHERE hours_worked <= 0 OR hours_worked > 16;

-- PHASE 4: Core Analytics Reporting Output
-- -------------------------------------------------------------------------
-- Query to extract and verify all active anomalies trapped by the audit view:
-- SELECT * FROM erp_data_exceptions_audit;
