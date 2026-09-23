-- ============================================================================
-- INSURANCE AI HUB - Complete DML Script (All 12 Tables)
-- Database: INSURANCE_AI_HUB
-- Run this AFTER the DDL script (INSURANCE_AI_HUB_DDL_DML.sql)
-- NOTE: This script is IDEMPOTENT — it truncates before inserting.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE WAREHOUSE COMPUTE_WH;

-- Truncate all tables in reverse-dependency order to allow re-runs
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.AGENT_AUDIT_LOG;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.BILLING;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.CLAIMS;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.POLICIES;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.AGENTS;


-- ############################################################################
-- SECTION 1: AGENTS (20 rows)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.ANALYTICS.AGENTS
(AGENT_ID, AGENT_NAME, AGENT_TYPE, REGION, BRANCH, HIRE_DATE, LICENSE_NUMBER, SPECIALIZATION, PERFORMANCE_RATING, ACTIVE_FLAG)
SELECT 
    'AGT-' || LPAD(SEQ4()::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 20)
        WHEN 0 THEN 'Sarah Johnson'       WHEN 1 THEN 'Michael Chen'
        WHEN 2 THEN 'Emily Rodriguez'     WHEN 3 THEN 'David Kim'
        WHEN 4 THEN 'Jessica Williams'    WHEN 5 THEN 'Robert Taylor'
        WHEN 6 THEN 'Amanda Martinez'     WHEN 7 THEN 'Christopher Lee'
        WHEN 8 THEN 'Michelle Brown'      WHEN 9 THEN 'Daniel Garcia'
        WHEN 10 THEN 'Lauren Davis'       WHEN 11 THEN 'James Wilson'
        WHEN 12 THEN 'Samantha Moore'     WHEN 13 THEN 'Andrew Jackson'
        WHEN 14 THEN 'Rachel Thompson'    WHEN 15 THEN 'Kevin White'
        WHEN 16 THEN 'Nicole Harris'      WHEN 17 THEN 'Brian Clark'
        WHEN 18 THEN 'Stephanie Lewis'    ELSE 'Thomas Robinson'
    END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'Underwriter' WHEN 1 THEN 'Claims Adjuster' ELSE 'Sales Agent' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'Northeast' WHEN 1 THEN 'Southeast' WHEN 2 THEN 'Midwest' WHEN 3 THEN 'Southwest' ELSE 'West' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'New York' WHEN 1 THEN 'Atlanta' WHEN 2 THEN 'Chicago' ELSE 'Dallas' END,
    DATEADD(DAY, -UNIFORM(365, 3650, RANDOM()), CURRENT_DATE()),
    'LIC-' || LPAD(UNIFORM(100000, 999999, RANDOM())::VARCHAR, 6, '0'),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Health Insurance' WHEN 1 THEN 'Auto Insurance' WHEN 2 THEN 'Life Insurance' ELSE 'Home Insurance' END,
    ROUND(UNIFORM(3.0, 5.0, RANDOM())::FLOAT, 1),
    TRUE
FROM TABLE(GENERATOR(ROWCOUNT => 20));


-- ############################################################################
-- SECTION 2: CUSTOMERS (200 rows)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
(CUSTOMER_ID, FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, EMAIL, PHONE, ADDRESS, CITY, STATE, ZIP_CODE, RISK_TIER, CREDIT_SCORE, CUSTOMER_SINCE, SEGMENT)
SELECT 
    'CUST-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    CASE MOD(SEQ4(), 20) 
        WHEN 0 THEN 'John' WHEN 1 THEN 'Jane' WHEN 2 THEN 'Robert' WHEN 3 THEN 'Maria'
        WHEN 4 THEN 'William' WHEN 5 THEN 'Linda' WHEN 6 THEN 'Richard' WHEN 7 THEN 'Patricia'
        WHEN 8 THEN 'Joseph' WHEN 9 THEN 'Barbara' WHEN 10 THEN 'Thomas' WHEN 11 THEN 'Elizabeth'
        WHEN 12 THEN 'Charles' WHEN 13 THEN 'Jennifer' WHEN 14 THEN 'Daniel' WHEN 15 THEN 'Susan'
        WHEN 16 THEN 'Matthew' WHEN 17 THEN 'Margaret' WHEN 18 THEN 'Anthony' ELSE 'Dorothy'
    END,
    CASE MOD(SEQ4(), 15)
        WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Brown' WHEN 3 THEN 'Davis'
        WHEN 4 THEN 'Miller' WHEN 5 THEN 'Wilson' WHEN 6 THEN 'Moore' WHEN 7 THEN 'Taylor'
        WHEN 8 THEN 'Anderson' WHEN 9 THEN 'Thomas' WHEN 10 THEN 'Jackson' WHEN 11 THEN 'White'
        WHEN 12 THEN 'Harris' WHEN 13 THEN 'Martin' ELSE 'Garcia'
    END,
    DATEADD(DAY, -UNIFORM(7300, 25550, RANDOM()), CURRENT_DATE()),
    CASE MOD(SEQ4(), 2) WHEN 0 THEN 'Male' ELSE 'Female' END,
    LOWER(CASE MOD(SEQ4(), 20) 
        WHEN 0 THEN 'john' WHEN 1 THEN 'jane' WHEN 2 THEN 'robert' WHEN 3 THEN 'maria'
        WHEN 4 THEN 'william' WHEN 5 THEN 'linda' WHEN 6 THEN 'richard' WHEN 7 THEN 'patricia'
        WHEN 8 THEN 'joseph' WHEN 9 THEN 'barbara' WHEN 10 THEN 'thomas' WHEN 11 THEN 'elizabeth'
        WHEN 12 THEN 'charles' WHEN 13 THEN 'jennifer' WHEN 14 THEN 'daniel' WHEN 15 THEN 'susan'
        WHEN 16 THEN 'matthew' WHEN 17 THEN 'margaret' WHEN 18 THEN 'anthony' ELSE 'dorothy'
    END) || SEQ4()::VARCHAR || '@email.com',
    '555-' || LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0'),
    UNIFORM(100, 9999, RANDOM())::VARCHAR || ' Main St',
    CASE MOD(SEQ4(), 10) WHEN 0 THEN 'New York' WHEN 1 THEN 'Los Angeles' WHEN 2 THEN 'Chicago' WHEN 3 THEN 'Houston' WHEN 4 THEN 'Phoenix' WHEN 5 THEN 'Philadelphia' WHEN 6 THEN 'San Antonio' WHEN 7 THEN 'San Diego' WHEN 8 THEN 'Dallas' ELSE 'Atlanta' END,
    CASE MOD(SEQ4(), 10) WHEN 0 THEN 'NY' WHEN 1 THEN 'CA' WHEN 2 THEN 'IL' WHEN 3 THEN 'TX' WHEN 4 THEN 'AZ' WHEN 5 THEN 'PA' WHEN 6 THEN 'TX' WHEN 7 THEN 'CA' WHEN 8 THEN 'TX' ELSE 'GA' END,
    LPAD(UNIFORM(10000, 99999, RANDOM())::VARCHAR, 5, '0'),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Low' WHEN 1 THEN 'Medium' WHEN 2 THEN 'High' ELSE 'Very High' END,
    UNIFORM(580, 850, RANDOM()),
    DATEADD(DAY, -UNIFORM(30, 2500, RANDOM()), CURRENT_DATE()),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Individual' WHEN 1 THEN 'Family' WHEN 2 THEN 'Corporate' ELSE 'Senior' END
FROM TABLE(GENERATOR(ROWCOUNT => 200));


-- ############################################################################
-- SECTION 3: POLICIES (300 rows)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.ANALYTICS.POLICIES
(POLICY_ID, CUSTOMER_ID, AGENT_ID, POLICY_TYPE, POLICY_STATUS, START_DATE, END_DATE, PREMIUM_AMOUNT, COVERAGE_AMOUNT, DEDUCTIBLE, LOSS_RATIO, PLAN_TIER, PAYMENT_FREQUENCY, AUTO_RENEW)
SELECT 
    'POL-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    'CUST-' || LPAD(UNIFORM(0, 199, RANDOM())::VARCHAR, 5, '0'),
    'AGT-' || LPAD(UNIFORM(0, 19, RANDOM())::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Health' WHEN 1 THEN 'Auto' WHEN 2 THEN 'Life' ELSE 'Home' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'Active' WHEN 1 THEN 'Active' WHEN 2 THEN 'Active' WHEN 3 THEN 'Expired' ELSE 'Cancelled' END,
    DATEADD(DAY, -UNIFORM(30, 730, RANDOM()), CURRENT_DATE()),
    DATEADD(DAY, UNIFORM(30, 365, RANDOM()), CURRENT_DATE()),
    ROUND(UNIFORM(500, 15000, RANDOM()), 2),
    ROUND(UNIFORM(50000, 1000000, RANDOM()), 2),
    ROUND(UNIFORM(250, 5000, RANDOM()), 2),
    ROUND(UNIFORM(0.15, 0.95, RANDOM())::FLOAT, 2),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Bronze' WHEN 1 THEN 'Silver' WHEN 2 THEN 'Gold' ELSE 'Platinum' END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'Monthly' WHEN 1 THEN 'Quarterly' ELSE 'Annual' END,
    CASE WHEN UNIFORM(0, 1, RANDOM()) > 0.3 THEN TRUE ELSE FALSE END
FROM TABLE(GENERATOR(ROWCOUNT => 300));


-- ############################################################################
-- SECTION 4: CLAIMS (400 rows)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.ANALYTICS.CLAIMS
(CLAIM_ID, POLICY_ID, CUSTOMER_ID, CLAIM_DATE, CLAIM_TYPE, CLAIM_STATUS, CLAIM_AMOUNT, APPROVED_AMOUNT, FRAUD_FLAG, FRAUD_SCORE, ASSIGNED_ADJUSTER, RESOLUTION_DATE, DAYS_TO_RESOLVE, FRICTION_POINT, PRIORITY)
SELECT 
    'CLM-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    'POL-' || LPAD(UNIFORM(0, 299, RANDOM())::VARCHAR, 5, '0'),
    'CUST-' || LPAD(UNIFORM(0, 199, RANDOM())::VARCHAR, 5, '0'),
    DATEADD(DAY, -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()),
    CASE MOD(SEQ4(), 6) WHEN 0 THEN 'Accident' WHEN 1 THEN 'Theft' WHEN 2 THEN 'Medical' WHEN 3 THEN 'Property Damage' WHEN 4 THEN 'Liability' ELSE 'Natural Disaster' END,
    CASE MOD(SEQ4(), 6) WHEN 0 THEN 'Open' WHEN 1 THEN 'Under Investigation' WHEN 2 THEN 'Approved' WHEN 3 THEN 'Closed' WHEN 4 THEN 'Denied' ELSE 'Escalated' END,
    ROUND(UNIFORM(500, 75000, RANDOM()), 2),
    CASE WHEN MOD(SEQ4(), 6) IN (2, 3) THEN ROUND(UNIFORM(400, 60000, RANDOM()), 2) ELSE NULL END,
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 8 THEN TRUE ELSE FALSE END,
    ROUND(UNIFORM(0.0, 1.0, RANDOM())::FLOAT, 2),
    CASE MOD(SEQ4(), 8) WHEN 0 THEN 'Sarah Johnson' WHEN 1 THEN 'Michael Chen' WHEN 2 THEN 'Emily Rodriguez' WHEN 3 THEN 'David Kim' WHEN 4 THEN 'Jessica Williams' WHEN 5 THEN 'Robert Taylor' WHEN 6 THEN 'Amanda Martinez' ELSE 'Christopher Lee' END,
    CASE WHEN MOD(SEQ4(), 6) IN (2, 3, 4) THEN DATEADD(DAY, -UNIFORM(1, 30, RANDOM()), CURRENT_DATE()) ELSE NULL END,
    CASE WHEN MOD(SEQ4(), 6) IN (2, 3, 4) THEN UNIFORM(1, 45, RANDOM()) ELSE NULL END,
    CASE MOD(SEQ4(), 8) WHEN 0 THEN 'Missing documentation' WHEN 1 THEN 'Adjuster backlog' WHEN 2 THEN 'Third-party delay' WHEN 3 THEN 'Policy verification pending' WHEN 4 THEN 'Medical records awaited' WHEN 5 THEN 'Investigation required' WHEN 6 THEN 'Customer unresponsive' ELSE 'System processing delay' END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'High' WHEN 1 THEN 'Medium' ELSE 'Low' END
FROM TABLE(GENERATOR(ROWCOUNT => 400));


-- ############################################################################
-- SECTION 5: BILLING (500 rows)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.ANALYTICS.BILLING
(BILLING_ID, POLICY_ID, CUSTOMER_ID, INVOICE_DATE, DUE_DATE, AMOUNT_DUE, AMOUNT_PAID, OUTSTANDING_BALANCE, PAYMENT_STATUS, PAYMENT_METHOD, PAYMENT_DATE, LATE_FEE)
SELECT 
    'BILL-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    'POL-' || LPAD(UNIFORM(0, 299, RANDOM())::VARCHAR, 5, '0'),
    'CUST-' || LPAD(UNIFORM(0, 199, RANDOM())::VARCHAR, 5, '0'),
    DATEADD(DAY, -UNIFORM(1, 180, RANDOM()), CURRENT_DATE()),
    DATEADD(DAY, -UNIFORM(0, 150, RANDOM()), CURRENT_DATE()),
    ROUND(UNIFORM(200, 5000, RANDOM()), 2),
    CASE WHEN MOD(SEQ4(), 5) < 3 THEN ROUND(UNIFORM(200, 5000, RANDOM()), 2) ELSE 0 END,
    CASE WHEN MOD(SEQ4(), 10) = 0 THEN ROUND(UNIFORM(10000, 25000, RANDOM()), 2) WHEN MOD(SEQ4(), 5) >= 3 THEN ROUND(UNIFORM(500, 9000, RANDOM()), 2) ELSE 0 END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'Paid' WHEN 1 THEN 'Paid' WHEN 2 THEN 'Paid' WHEN 3 THEN 'Overdue' ELSE 'Pending' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Credit Card' WHEN 1 THEN 'Bank Transfer' WHEN 2 THEN 'Auto-Debit' ELSE 'Check' END,
    CASE WHEN MOD(SEQ4(), 5) < 3 THEN DATEADD(DAY, -UNIFORM(0, 30, RANDOM()), CURRENT_DATE()) ELSE NULL END,
    CASE WHEN MOD(SEQ4(), 5) >= 3 THEN ROUND(UNIFORM(25, 150, RANDOM()), 2) ELSE 0 END
FROM TABLE(GENERATOR(ROWCOUNT => 500));


-- ############################################################################
-- SECTION 6: AT_RISK_POLICIES (165 rows)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES
(RISK_ID, POLICY_ID, CUSTOMER_ID, RISK_CATEGORY, RISK_SCORE, REVENUE_AT_RISK, CHURN_PROBABILITY, LAST_INTERACTION_DATE, DAYS_SINCE_CONTACT, COMPLAINTS_COUNT, MISSED_PAYMENTS, RECOMMENDED_ACTION, IDENTIFIED_DATE)
SELECT 
    'RISK-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    'POL-' || LPAD(UNIFORM(0, 299, RANDOM())::VARCHAR, 5, '0'),
    'CUST-' || LPAD(UNIFORM(0, 199, RANDOM())::VARCHAR, 5, '0'),
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'Payment Default' WHEN 1 THEN 'High Claims Frequency' WHEN 2 THEN 'Customer Complaint' WHEN 3 THEN 'Policy Lapse Risk' ELSE 'Competitive Switch' END,
    ROUND(UNIFORM(0.55, 0.98, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(1500, 8500, RANDOM()), 2),
    ROUND(UNIFORM(0.4, 0.95, RANDOM())::FLOAT, 2),
    DATEADD(DAY, -UNIFORM(15, 120, RANDOM()), CURRENT_DATE()),
    UNIFORM(15, 120, RANDOM()),
    UNIFORM(1, 8, RANDOM()),
    UNIFORM(0, 4, RANDOM()),
    CASE MOD(SEQ4(), 6) WHEN 0 THEN 'Immediate outreach by retention team' WHEN 1 THEN 'Offer premium discount for renewal' WHEN 2 THEN 'Escalate to account manager' WHEN 3 THEN 'Send policy benefits reminder' WHEN 4 THEN 'Schedule claims review meeting' ELSE 'Initiate loyalty program enrollment' END,
    DATEADD(DAY, -UNIFORM(1, 60, RANDOM()), CURRENT_DATE())
FROM TABLE(GENERATOR(ROWCOUNT => 165));
-- ============================================================================
-- INSURANCE AI HUB - DML Part 2: Documents & Data Quality Tables
-- Database: INSURANCE_AI_HUB
-- Run AFTER Part 1 (INSURANCE_AI_HUB_DML.sql)
-- ============================================================================


-- ############################################################################
-- SECTION 7: POLICY_DOCUMENTS (10 rows)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
(DOCUMENT_ID, POLICY_ID, DOCUMENT_TYPE, DOCUMENT_TITLE, FILE_NAME, FILE_FORMAT, UPLOAD_DATE, CONTENT_TEXT, EXCLUSION_CLAUSES, COVERAGE_SUMMARY, PAGE_COUNT, DOCUMENT_STATUS)
VALUES
('DOC-00001','POL-00001','Policy Contract','Standard Health Insurance Policy','health_policy_001.pdf','PDF','2024-01-15','This Health Insurance Policy provides comprehensive medical coverage including hospitalization, outpatient care, prescription medications, and preventive services.','Pre-existing conditions within first 12 months. Cosmetic surgery unless medically necessary. Experimental treatments not approved by FDA. Self-inflicted injuries. Injuries from illegal activities.','Covers hospitalization up to $500K, outpatient visits $100 copay, prescriptions 80% coverage, preventive care 100% covered.',24,'Active'),
('DOC-00002','POL-00005','Policy Contract','Comprehensive Auto Insurance Policy','auto_policy_005.pdf','PDF','2024-02-20','This Automobile Insurance Policy provides liability, collision, and comprehensive coverage for the insured vehicle.','Racing or speed contests. Commercial use of personal vehicle. Intentional damage. Driving under influence of drugs/alcohol. Wear and tear or mechanical breakdown. Nuclear radiation damage.','Liability $300K/$500K, Collision with $1000 deductible, Comprehensive with $500 deductible, Uninsured motorist $100K.',18,'Active'),
('DOC-00003','POL-00010','Policy Contract','Term Life Insurance Policy','life_policy_010.pdf','PDF','2024-03-10','This Term Life Insurance Policy provides death benefit coverage for a specified term of 20 years.','Suicide within first 2 years. Death from illegal activities. Death while participating in hazardous sports without rider. Misrepresentation of health on application. War or acts of terrorism.','Death benefit $1M, Accidental death rider $500K additional, Terminal illness accelerated benefit up to 50%.',15,'Active'),
('DOC-00004','POL-00015','Policy Contract','Homeowners Insurance Policy','home_policy_015.pdf','PDF','2024-01-30','This Homeowners Insurance Policy protects the dwelling, personal property, and provides liability coverage.','Flood damage (separate policy required). Earthquake damage. Normal wear and deterioration. Insect or vermin damage. Government actions. Nuclear hazard. Intentional loss by insured.','Dwelling coverage $450K, Personal property $225K, Liability $300K, Additional living expenses $90K.',22,'Active'),
('DOC-00005','POL-00020','Policy Contract','Health Insurance Gold Plan','health_gold_020.pdf','PDF','2024-04-05','This Gold Plan Health Insurance provides enhanced coverage including lower deductibles and expanded network access.','Bariatric surgery for BMI under 40. Non-emergency international care. Long-term custodial care. Services not deemed medically necessary. Infertility treatments beyond 3 cycles IVF.','Deductible $500 individual, Out-of-pocket max $3000, Specialist visits $30 copay, ER $150 copay, Mental health covered at parity.',28,'Active'),
('DOC-00006','POL-00025','Policy Contract','Commercial Auto Fleet Policy','fleet_policy_025.pdf','PDF','2024-02-28','This Commercial Auto Fleet Policy covers multiple vehicles registered under the business entity.','Personal use of fleet vehicles. Vehicles not listed on schedule. Drivers under age 21. Transport of hazardous materials without endorsement. Rental or leasing to third parties.','Fleet liability $1M combined single limit, Physical damage actual cash value, Hired/non-owned auto $500K, Cargo coverage $100K.',20,'Active'),
('DOC-00007','POL-00030','Endorsement','Umbrella Liability Endorsement','umbrella_030.pdf','PDF','2024-03-22','This Umbrella Liability Endorsement provides excess liability coverage above the limits of underlying policies.','Professional liability. Workers compensation. Contractual liability assumed prior to policy inception. Aircraft or watercraft over 50 feet. Punitive damages where prohibited by law.','Umbrella limit $2M per occurrence, $4M aggregate. Covers personal injury, property damage, and advertising injury.',8,'Active'),
('DOC-00008','POL-00035','Policy Contract','Disability Income Insurance','disability_035.pdf','PDF','2024-04-15','This Disability Income Insurance Policy provides monthly income replacement benefits when unable to perform occupation duties.','Self-inflicted injuries. Disability from commission of felony. Pre-existing conditions first 12 months. Disability during incarceration. Normal pregnancy (complications covered).','Monthly benefit $8,000, 90-day elimination period, Benefits payable to age 65, Own occupation definition first 5 years.',12,'Active'),
('DOC-00009','POL-00040','Claim Form','Auto Accident Claim Documentation','claim_form_040.pdf','PDF','2024-05-01','Claim documentation for auto accident on Highway 101. Rear-end collision at traffic signal. Police report filed.','N/A - Claim Form','Claim amount $8,500 for vehicle repair. Rental car coverage during repair period up to 30 days at $50/day.',6,'Processed'),
('DOC-00010','POL-00045','Policy Contract','Workers Compensation Policy','workers_comp_045.pdf','PDF','2024-03-01','This Workers Compensation Insurance Policy provides coverage for employee injuries and illnesses arising out of employment.','Injuries from employee intoxication. Self-inflicted injuries. Injuries during voluntary recreational activities. Independent contractors (unless misclassified). Intentional acts by employer.','Coverage per state statutory requirements, Employers liability $1M each accident, $1M disease each employee, $1M disease policy limit.',16,'Active');


-- ############################################################################
-- SECTION 8: DOCUMENT_CHUNKS (25 rows - For RAG Vector Search)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS
(CHUNK_ID, DOCUMENT_ID, CHUNK_INDEX, CHUNK_TEXT, SECTION_TITLE, TOKEN_COUNT)
VALUES
('CHK-00001','DOC-00001',1,'This Health Insurance Policy provides comprehensive medical coverage including hospitalization, outpatient care, prescription medications, and preventive services. Coverage begins on the effective date shown on the declarations page.','Coverage Overview',52),
('CHK-00002','DOC-00001',2,'EXCLUSIONS: Pre-existing conditions within the first 12 months. Cosmetic surgery unless medically necessary. Experimental treatments not approved by FDA. Self-inflicted injuries. Injuries during illegal activities.','Exclusion Clauses',58),
('CHK-00003','DOC-00001',3,'BENEFITS SCHEDULE: Hospitalization up to $500,000. Outpatient visits $100 copay. Prescriptions 80% after deductible. Preventive care 100% no copay. Mental health at parity.','Benefits Schedule',55),
('CHK-00004','DOC-00002',1,'This Automobile Insurance Policy provides liability, collision, and comprehensive coverage. Named insured and household members with valid licenses are covered.','Policy Coverage',48),
('CHK-00005','DOC-00002',2,'EXCLUSIONS: Racing or speed contests. Commercial use of personal vehicle. Intentional damage. Operating under influence. Normal wear and tear or mechanical breakdown.','Auto Exclusions',52),
('CHK-00006','DOC-00002',3,'LIABILITY LIMITS: Bodily injury $300K/$500K. Property damage $100K. Collision $1,000 deductible. Comprehensive $500 deductible. Uninsured motorist $100K.','Liability Limits',45),
('CHK-00007','DOC-00003',1,'Term Life Policy: Death benefit $1,000,000 during 20-year term. Guaranteed level premiums. Accelerated death benefit rider up to 50% upon terminal illness.','Life Coverage Terms',60),
('CHK-00008','DOC-00003',2,'EXCLUSIONS: Suicide within first two years. Death from felony commission. Hazardous activities without rider (skydiving, bungee jumping, rock climbing).','Life Exclusions',55),
('CHK-00009','DOC-00004',1,'DWELLING COVERAGE: $450,000 replacement cost. Includes structure, attached structures, building materials. Additional structures at 10% of dwelling coverage.','Dwelling Coverage',50),
('CHK-00010','DOC-00004',2,'EXCLUSIONS: Flood (separate policy required). Earthquake. Wear and tear. Insect or vermin infestation. Government actions. Nuclear hazard.','Home Exclusions',48),
('CHK-00011','DOC-00004',3,'PERSONAL PROPERTY: $225,000 actual cash value. Limits: Cash $200, Jewelry $1,500 unless scheduled, Electronics $2,500. Away from premises at 10%.','Personal Property',45),
('CHK-00012','DOC-00005',1,'GOLD PLAN: Deductible $500/$1,000. Out-of-pocket max $3,000/$6,000. Primary care $20. Specialist $30. Urgent $50. ER $150 waived if admitted.','Gold Plan Benefits',52),
('CHK-00013','DOC-00005',2,'GOLD PLAN EXCLUSIONS: Bariatric surgery BMI under 40. Non-emergency international care. Long-term custodial care. Not medically necessary. Infertility beyond 3 IVF cycles.','Gold Plan Exclusions',55),
('CHK-00014','DOC-00006',1,'FLEET COVERAGE: All vehicles on schedule covered. Combined single limit $1,000,000. Physical damage actual cash value, $2,500 deductible per vehicle.','Fleet Coverage',42),
('CHK-00015','DOC-00006',2,'FLEET EXCLUSIONS: Personal use. Vehicles not on schedule. Drivers under 21. Hazardous materials without endorsement. Rental to third parties.','Fleet Exclusions',48),
('CHK-00016','DOC-00007',1,'UMBRELLA: Excess coverage $2,000,000 per occurrence, $4,000,000 aggregate. Drops down as primary for uncovered claims, $10,000 self-insured retention.','Umbrella Terms',45),
('CHK-00017','DOC-00008',1,'DISABILITY: Monthly $8,000 after 90-day elimination. Benefits to age 65. Own occupation first 5 years, any occupation thereafter. COLA 3% annually.','Disability Benefits',50),
('CHK-00018','DOC-00008',2,'DISABILITY EXCLUSIONS: Self-inflicted injuries. Felony commission. Pre-existing conditions first 12 months. Incarceration. Normal pregnancy (complications covered).','Disability Exclusions',48),
('CHK-00019','DOC-00009',1,'CLAIM: April 28, 2024, 3:15 PM. 2022 Toyota Camry rear-ended at red light, Highway 101. Other vehicle 2020 Ford F-150. Police report #2024-05891.','Claim Narrative',55),
('CHK-00020','DOC-00010',1,'WORKERS COMP: Statutory benefits per state law. Employers liability $1M each accident, $1M disease per employee, $1M disease policy limit.','Workers Comp Coverage',48),
('CHK-00021','DOC-00001',4,'CLAIM FILING: Must file within 90 days. Pre-authorization required for inpatient, surgeries, advanced imaging. Emergency services no pre-auth needed.','Claim Procedures',42),
('CHK-00022','DOC-00002',4,'CLAIM REPORTING: Report accidents within 24 hours. Police report required for theft and injury. Must cooperate with investigation. Late reporting may cause denial.','Claim Reporting',38),
('CHK-00023','DOC-00003',3,'BENEFICIARY: May change anytime by written request. No beneficiary surviving = paid to estate. Contingent beneficiaries if primary predeceases.','Beneficiary Info',40),
('CHK-00024','DOC-00004',4,'LIABILITY: Personal liability $300,000 per occurrence. Medical payments to others $5,000. Worldwide coverage. Defense costs in addition to limits.','Home Liability',38),
('CHK-00025','DOC-00010',2,'WORKERS COMP EXCLUSIONS: Voluntary intoxication. Self-inflicted injury. Off-duty recreational activities. Independent contractor properly classified.','Workers Comp Exclusions',48);


-- ############################################################################
-- SECTION 9: DQ_RULES (50 rules)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES
(RULE_ID, RULE_NAME, RULE_DESCRIPTION, TARGET_TABLE, TARGET_COLUMN, RULE_TYPE, RULE_EXPRESSION, SEVERITY, IS_CRITICAL, THRESHOLD_PCT, ACTIVE_FLAG)
VALUES
('DQR-001','NOT_NULL_CUSTOMER_ID','Customer ID must not be null','CUSTOMERS','CUSTOMER_ID','Completeness','CUSTOMER_ID IS NOT NULL','Critical',TRUE,100,TRUE),
('DQR-002','NOT_NULL_POLICY_ID','Policy ID must not be null','POLICIES','POLICY_ID','Completeness','POLICY_ID IS NOT NULL','Critical',TRUE,100,TRUE),
('DQR-003','VALID_POLICY_TYPE','Policy type must be Health/Auto/Life/Home','POLICIES','POLICY_TYPE','Validity','POLICY_TYPE IN (''Health'',''Auto'',''Life'',''Home'')','High',TRUE,100,TRUE),
('DQR-004','PREMIUM_POSITIVE','Premium amount must be positive','POLICIES','PREMIUM_AMOUNT','Accuracy','PREMIUM_AMOUNT > 0','Critical',TRUE,100,TRUE),
('DQR-005','VALID_EMAIL_FORMAT','Email must contain @ symbol','CUSTOMERS','EMAIL','Format','EMAIL LIKE ''%@%''','Medium',FALSE,95,TRUE),
('DQR-006','VALID_CREDIT_SCORE','Credit score between 300-850','CUSTOMERS','CREDIT_SCORE','Range','CREDIT_SCORE BETWEEN 300 AND 850','High',FALSE,99,TRUE),
('DQR-007','CLAIM_AMOUNT_POSITIVE','Claim amount must be positive','CLAIMS','CLAIM_AMOUNT','Accuracy','CLAIM_AMOUNT > 0','Critical',TRUE,100,TRUE),
('DQR-008','VALID_CLAIM_STATUS','Claim status must be valid enum','CLAIMS','CLAIM_STATUS','Validity','CLAIM_STATUS IN (''Open'',''Under Investigation'',''Approved'',''Closed'',''Denied'',''Escalated'')','High',TRUE,100,TRUE),
('DQR-009','RESOLUTION_DATE_LOGIC','Resolution date after claim date','CLAIMS','RESOLUTION_DATE','Consistency','RESOLUTION_DATE IS NULL OR RESOLUTION_DATE >= CLAIM_DATE','High',TRUE,100,TRUE),
('DQR-010','NOT_NULL_CLAIM_DATE','Claim date must not be null','CLAIMS','CLAIM_DATE','Completeness','CLAIM_DATE IS NOT NULL','Critical',TRUE,100,TRUE),
('DQR-011','VALID_STATE_CODE','State code must be 2 characters','CUSTOMERS','STATE','Format','LENGTH(STATE) = 2','Medium',FALSE,98,TRUE),
('DQR-012','VALID_PHONE_FORMAT','Phone must match pattern','CUSTOMERS','PHONE','Format','PHONE LIKE ''555-%''','Low',FALSE,90,TRUE),
('DQR-013','COVERAGE_GT_PREMIUM','Coverage must exceed premium','POLICIES','COVERAGE_AMOUNT','Consistency','COVERAGE_AMOUNT > PREMIUM_AMOUNT','High',TRUE,99,TRUE),
('DQR-014','VALID_LOSS_RATIO','Loss ratio between 0 and 1','POLICIES','LOSS_RATIO','Range','LOSS_RATIO BETWEEN 0 AND 1','Medium',FALSE,100,TRUE),
('DQR-015','END_AFTER_START','Policy end date after start date','POLICIES','END_DATE','Consistency','END_DATE > START_DATE','Critical',TRUE,100,TRUE),
('DQR-016','NOT_NULL_FIRST_NAME','First name must not be null','CUSTOMERS','FIRST_NAME','Completeness','FIRST_NAME IS NOT NULL','High',TRUE,100,TRUE),
('DQR-017','NOT_NULL_LAST_NAME','Last name must not be null','CUSTOMERS','LAST_NAME','Completeness','LAST_NAME IS NOT NULL','High',TRUE,100,TRUE),
('DQR-018','VALID_GENDER','Gender must be Male/Female','CUSTOMERS','GENDER','Validity','GENDER IN (''Male'',''Female'')','Low',FALSE,100,TRUE),
('DQR-019','VALID_RISK_TIER','Risk tier must be valid category','CUSTOMERS','RISK_TIER','Validity','RISK_TIER IN (''Low'',''Medium'',''High'',''Very High'')','Medium',FALSE,100,TRUE),
('DQR-020','FRAUD_SCORE_RANGE','Fraud score between 0 and 1','CLAIMS','FRAUD_SCORE','Range','FRAUD_SCORE BETWEEN 0 AND 1','Medium',FALSE,100,TRUE),
('DQR-021','NOT_NULL_AGENT_NAME','Agent name must not be null','AGENTS','AGENT_NAME','Completeness','AGENT_NAME IS NOT NULL','High',TRUE,100,TRUE),
('DQR-022','VALID_AGENT_RATING','Performance rating 1-5','AGENTS','PERFORMANCE_RATING','Range','PERFORMANCE_RATING BETWEEN 1 AND 5','Medium',FALSE,100,TRUE),
('DQR-023','AMOUNT_DUE_POSITIVE','Billing amount must be positive','BILLING','AMOUNT_DUE','Accuracy','AMOUNT_DUE > 0','High',TRUE,100,TRUE),
('DQR-024','VALID_PAYMENT_STATUS','Payment status must be valid','BILLING','PAYMENT_STATUS','Validity','PAYMENT_STATUS IN (''Paid'',''Overdue'',''Pending'')','Medium',FALSE,100,TRUE),
('DQR-025','DUE_DATE_AFTER_INVOICE','Due date after invoice date','BILLING','DUE_DATE','Consistency','DUE_DATE >= INVOICE_DATE','High',TRUE,98,TRUE),
('DQR-026','NOT_NULL_DOB','Date of birth must not be null','CUSTOMERS','DATE_OF_BIRTH','Completeness','DATE_OF_BIRTH IS NOT NULL','High',FALSE,99,TRUE),
('DQR-027','VALID_ZIP_CODE','Zip code must be 5 digits','CUSTOMERS','ZIP_CODE','Format','LENGTH(ZIP_CODE) = 5','Medium',FALSE,95,TRUE),
('DQR-028','RISK_SCORE_RANGE','Risk score between 0 and 1','AT_RISK_POLICIES','RISK_SCORE','Range','RISK_SCORE BETWEEN 0 AND 1','High',FALSE,100,TRUE),
('DQR-029','REVENUE_RISK_POSITIVE','Revenue at risk must be positive','AT_RISK_POLICIES','REVENUE_AT_RISK','Accuracy','REVENUE_AT_RISK > 0','High',TRUE,100,TRUE),
('DQR-030','CHURN_PROB_RANGE','Churn probability between 0 and 1','AT_RISK_POLICIES','CHURN_PROBABILITY','Range','CHURN_PROBABILITY BETWEEN 0 AND 1','Medium',FALSE,100,TRUE),
('DQR-031','NOT_NULL_CLAIM_TYPE','Claim type must not be null','CLAIMS','CLAIM_TYPE','Completeness','CLAIM_TYPE IS NOT NULL','High',TRUE,100,TRUE),
('DQR-032','APPROVED_LTE_CLAIMED','Approved amount cannot exceed claimed','CLAIMS','APPROVED_AMOUNT','Consistency','APPROVED_AMOUNT IS NULL OR APPROVED_AMOUNT <= CLAIM_AMOUNT','High',TRUE,95,TRUE),
('DQR-033','VALID_PRIORITY','Priority must be High/Medium/Low','CLAIMS','PRIORITY','Validity','PRIORITY IN (''High'',''Medium'',''Low'')','Low',FALSE,100,TRUE),
('DQR-034','VALID_PLAN_TIER','Plan tier must be valid','POLICIES','PLAN_TIER','Validity','PLAN_TIER IN (''Bronze'',''Silver'',''Gold'',''Platinum'')','Medium',FALSE,100,TRUE),
('DQR-035','VALID_PAYMENT_FREQ','Payment frequency must be valid','POLICIES','PAYMENT_FREQUENCY','Validity','PAYMENT_FREQUENCY IN (''Monthly'',''Quarterly'',''Annual'')','Low',FALSE,100,TRUE),
('DQR-036','DEDUCTIBLE_LT_COVERAGE','Deductible less than coverage','POLICIES','DEDUCTIBLE','Consistency','DEDUCTIBLE < COVERAGE_AMOUNT','Critical',TRUE,100,TRUE),
('DQR-037','CUSTOMER_AGE_VALID','Customer not older than 100','CUSTOMERS','DATE_OF_BIRTH','Range','DATEDIFF(YEAR, DATE_OF_BIRTH, CURRENT_DATE()) <= 100','Low',FALSE,100,TRUE),
('DQR-038','NOT_NULL_INVOICE_DATE','Invoice date must not be null','BILLING','INVOICE_DATE','Completeness','INVOICE_DATE IS NOT NULL','High',TRUE,100,TRUE),
('DQR-039','BALANCE_NON_NEGATIVE','Outstanding balance non-negative','BILLING','OUTSTANDING_BALANCE','Accuracy','OUTSTANDING_BALANCE >= 0','High',TRUE,100,TRUE),
('DQR-040','LATE_FEE_NON_NEGATIVE','Late fee must be non-negative','BILLING','LATE_FEE','Accuracy','LATE_FEE >= 0','Medium',FALSE,100,TRUE),
('DQR-041','NOT_NULL_RISK_CATEGORY','Risk category must not be null','AT_RISK_POLICIES','RISK_CATEGORY','Completeness','RISK_CATEGORY IS NOT NULL','High',TRUE,100,TRUE),
('DQR-042','DAYS_SINCE_CONTACT_POS','Days since contact must be positive','AT_RISK_POLICIES','DAYS_SINCE_CONTACT','Accuracy','DAYS_SINCE_CONTACT > 0','Medium',FALSE,100,TRUE),
('DQR-043','MISSED_PAYMENTS_RANGE','Missed payments 0-12','AT_RISK_POLICIES','MISSED_PAYMENTS','Range','MISSED_PAYMENTS BETWEEN 0 AND 12','Low',FALSE,100,TRUE),
('DQR-044','VALID_REGION','Region must be valid','AGENTS','REGION','Validity','REGION IN (''Northeast'',''Southeast'',''Midwest'',''Southwest'',''West'')','Low',FALSE,100,TRUE),
('DQR-045','NOT_NULL_LICENSE','License number must not be null','AGENTS','LICENSE_NUMBER','Completeness','LICENSE_NUMBER IS NOT NULL','High',TRUE,100,TRUE),
('DQR-046','TIMELINESS_CLAIM_DATA','Claims data updated within 24hrs','CLAIMS','CREATED_AT','Timeliness','DATEDIFF(HOUR, CREATED_AT, CURRENT_TIMESTAMP()) <= 24','High',FALSE,95,TRUE),
('DQR-047','UNIQUE_CUSTOMER_EMAIL','Email must be unique per customer','CUSTOMERS','EMAIL','Uniqueness','COUNT(DISTINCT CUSTOMER_ID) = COUNT(DISTINCT EMAIL)','Medium',FALSE,99,TRUE),
('DQR-048','FK_POLICY_CUSTOMER','Policy must reference valid customer','POLICIES','CUSTOMER_ID','Referential','CUSTOMER_ID IN (SELECT CUSTOMER_ID FROM CUSTOMERS)','Critical',TRUE,100,TRUE),
('DQR-049','FK_CLAIM_POLICY','Claim must reference valid policy','CLAIMS','POLICY_ID','Referential','POLICY_ID IN (SELECT POLICY_ID FROM POLICIES)','Critical',TRUE,100,TRUE),
('DQR-050','DOCUMENT_HAS_CONTENT','Document must have content text','POLICY_DOCUMENTS','CONTENT_TEXT','Completeness','CONTENT_TEXT IS NOT NULL AND LENGTH(CONTENT_TEXT) > 0','High',TRUE,100,TRUE);


-- ############################################################################
-- SECTION 10: DQ_SCORES (28 rows - Weekly History)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
(SCORE_ID, TABLE_NAME, SCHEMA_NAME, SCORE_DATE, OVERALL_SCORE, COMPLETENESS_SCORE, ACCURACY_SCORE, CONSISTENCY_SCORE, TIMELINESS_SCORE, RULES_PASSED, RULES_FAILED, TOTAL_RULES, TREND)
VALUES
('DQS-001','CUSTOMERS','ANALYTICS','2025-01-01',92.5,98.0,90.0,88.0,94.0,18,2,20,'UP'),
('DQS-002','CUSTOMERS','ANALYTICS','2025-01-08',91.0,97.5,89.0,87.5,90.0,17,3,20,'DOWN'),
('DQS-003','CUSTOMERS','ANALYTICS','2025-01-15',72.0,85.0,68.0,65.0,70.0,14,6,20,'DOWN'),
('DQS-004','CUSTOMERS','ANALYTICS','2025-01-22',74.5,86.0,70.0,66.0,76.0,15,5,20,'UP'),
('DQS-005','POLICIES','ANALYTICS','2025-01-01',95.0,100.0,93.0,92.0,95.0,14,1,15,'STABLE'),
('DQS-006','POLICIES','ANALYTICS','2025-01-08',94.5,100.0,92.5,91.0,94.5,14,1,15,'STABLE'),
('DQS-007','POLICIES','ANALYTICS','2025-01-15',88.0,98.0,85.0,82.0,87.0,12,3,15,'DOWN'),
('DQS-008','POLICIES','ANALYTICS','2025-01-22',90.0,99.0,87.0,85.0,89.0,13,2,15,'UP'),
('DQS-009','CLAIMS','ANALYTICS','2025-01-01',89.0,95.0,87.0,85.0,89.0,11,2,13,'STABLE'),
('DQS-010','CLAIMS','ANALYTICS','2025-01-08',86.5,94.0,84.0,82.0,86.0,10,3,13,'DOWN'),
('DQS-011','CLAIMS','ANALYTICS','2025-01-15',83.0,92.0,80.0,78.0,82.0,9,4,13,'DOWN'),
('DQS-012','CLAIMS','ANALYTICS','2025-01-22',85.0,93.0,82.0,80.5,84.5,10,3,13,'UP'),
('DQS-013','BILLING','ANALYTICS','2025-01-01',96.0,100.0,95.0,94.0,95.0,7,0,7,'STABLE'),
('DQS-014','BILLING','ANALYTICS','2025-01-08',95.5,100.0,94.0,93.0,95.0,7,0,7,'STABLE'),
('DQS-015','BILLING','ANALYTICS','2025-01-15',91.0,98.0,88.0,87.0,91.0,6,1,7,'DOWN'),
('DQS-016','BILLING','ANALYTICS','2025-01-22',93.0,99.0,90.0,89.0,94.0,6,1,7,'UP'),
('DQS-017','AT_RISK_POLICIES','ANALYTICS','2025-01-01',90.0,96.0,88.0,86.0,90.0,8,1,9,'STABLE'),
('DQS-018','AT_RISK_POLICIES','ANALYTICS','2025-01-08',89.0,95.0,87.0,85.0,89.0,8,1,9,'DOWN'),
('DQS-019','AT_RISK_POLICIES','ANALYTICS','2025-01-15',85.0,92.0,83.0,80.0,85.0,7,2,9,'DOWN'),
('DQS-020','AT_RISK_POLICIES','ANALYTICS','2025-01-22',87.0,94.0,85.0,82.0,87.0,7,2,9,'UP'),
('DQS-021','AGENTS','ANALYTICS','2025-01-01',98.0,100.0,97.0,98.0,97.0,5,0,5,'STABLE'),
('DQS-022','AGENTS','ANALYTICS','2025-01-08',98.0,100.0,97.0,98.0,97.0,5,0,5,'STABLE'),
('DQS-023','AGENTS','ANALYTICS','2025-01-15',97.5,100.0,96.0,97.0,97.0,5,0,5,'STABLE'),
('DQS-024','AGENTS','ANALYTICS','2025-01-22',98.0,100.0,97.0,98.0,97.0,5,0,5,'STABLE'),
('DQS-025','POLICY_DOCUMENTS','DOCUMENTS','2025-01-01',94.0,98.0,92.0,91.0,95.0,3,0,3,'STABLE'),
('DQS-026','POLICY_DOCUMENTS','DOCUMENTS','2025-01-08',93.5,97.0,91.0,90.0,96.0,3,0,3,'STABLE'),
('DQS-027','POLICY_DOCUMENTS','DOCUMENTS','2025-01-15',90.0,95.0,87.0,85.0,93.0,2,1,3,'DOWN'),
('DQS-028','POLICY_DOCUMENTS','DOCUMENTS','2025-01-22',92.0,96.0,90.0,88.0,94.0,3,0,3,'UP');


-- ############################################################################
-- SECTION 11: DQ_RESULTS & DQ_COLUMN_HEALTH
-- (40 results + 28 column health records)
-- See INSURANCE_AI_HUB_DML_DQ_RESULTS.sql for full data
-- ############################################################################

-- ============================================================================
-- END OF DML PART 2
-- ============================================================================
-- ============================================================================
-- INSURANCE AI HUB - DML Part 3: DQ Results & Column Health
-- Database: INSURANCE_AI_HUB
-- Run AFTER Part 2 (INSURANCE_AI_HUB_DML_PART2.sql)
-- ============================================================================


-- ############################################################################
-- SECTION 1: DQ_RESULTS (40 rows - Rule Execution Results)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS
(RESULT_ID, RULE_ID, EXECUTION_DATE, TARGET_TABLE, TARGET_COLUMN, TOTAL_RECORDS, PASSED_RECORDS, FAILED_RECORDS, PASS_RATE, STATUS, ERROR_SAMPLE)
VALUES
-- Jan 15 execution (shows degradation)
('RES-001','DQR-001','2025-01-15 08:00:00','CUSTOMERS','CUSTOMER_ID',200,200,0,100.0,'PASS',NULL),
('RES-002','DQR-005','2025-01-15 08:00:00','CUSTOMERS','EMAIL',200,192,8,96.0,'PASS','john.smith, no_at_sign.com, badformat'),
('RES-003','DQR-006','2025-01-15 08:00:00','CUSTOMERS','CREDIT_SCORE',200,195,5,97.5,'PASS','Values found: 275, 290, 855, 860, 870'),
('RES-004','DQR-011','2025-01-15 08:00:00','CUSTOMERS','STATE',200,180,20,90.0,'FAIL','Values: NYC, CAL, TEX, FLO (not 2-char codes)'),
('RES-005','DQR-012','2025-01-15 08:00:00','CUSTOMERS','PHONE',200,160,40,80.0,'FAIL','Formats: (555)123-4567, 5551234567, +1-555-1234'),
('RES-006','DQR-016','2025-01-15 08:00:00','CUSTOMERS','FIRST_NAME',200,198,2,99.0,'PASS','2 NULL values found in FIRST_NAME'),
('RES-007','DQR-026','2025-01-15 08:00:00','CUSTOMERS','DATE_OF_BIRTH',200,185,15,92.5,'FAIL','15 records with NULL date_of_birth'),
('RES-008','DQR-027','2025-01-15 08:00:00','CUSTOMERS','ZIP_CODE',200,170,30,85.0,'FAIL','Values: 1234, 123456, ABCDE, 0000'),
('RES-009','DQR-047','2025-01-15 08:00:00','CUSTOMERS','EMAIL',200,188,12,94.0,'FAIL','12 duplicate emails across different customer IDs'),
('RES-010','DQR-002','2025-01-15 08:05:00','POLICIES','POLICY_ID',300,300,0,100.0,'PASS',NULL),
('RES-011','DQR-003','2025-01-15 08:05:00','POLICIES','POLICY_TYPE',300,300,0,100.0,'PASS',NULL),
('RES-012','DQR-004','2025-01-15 08:05:00','POLICIES','PREMIUM_AMOUNT',300,298,2,99.3,'PASS','2 records with $0 premium'),
('RES-013','DQR-013','2025-01-15 08:05:00','POLICIES','COVERAGE_AMOUNT',300,285,15,95.0,'FAIL','15 policies where coverage <= premium'),
('RES-014','DQR-015','2025-01-15 08:05:00','POLICIES','END_DATE',300,295,5,98.3,'PASS','5 policies with end_date = start_date'),
('RES-015','DQR-048','2025-01-15 08:05:00','POLICIES','CUSTOMER_ID',300,280,20,93.3,'FAIL','20 policies reference non-existent customer IDs'),
('RES-016','DQR-007','2025-01-15 08:10:00','CLAIMS','CLAIM_AMOUNT',400,400,0,100.0,'PASS',NULL),
('RES-017','DQR-008','2025-01-15 08:10:00','CLAIMS','CLAIM_STATUS',400,400,0,100.0,'PASS',NULL),
('RES-018','DQR-009','2025-01-15 08:10:00','CLAIMS','RESOLUTION_DATE',400,385,15,96.3,'FAIL','15 claims with resolution_date before claim_date'),
('RES-019','DQR-010','2025-01-15 08:10:00','CLAIMS','CLAIM_DATE',400,400,0,100.0,'PASS',NULL),
('RES-020','DQR-032','2025-01-15 08:10:00','CLAIMS','APPROVED_AMOUNT',400,370,30,92.5,'FAIL','30 claims where approved > claimed amount'),
('RES-021','DQR-049','2025-01-15 08:10:00','CLAIMS','POLICY_ID',400,360,40,90.0,'FAIL','40 claims reference non-existent policy IDs'),
('RES-022','DQR-046','2025-01-15 08:10:00','CLAIMS','CREATED_AT',400,380,20,95.0,'PASS','20 records older than 24hrs since last update'),
('RES-023','DQR-023','2025-01-15 08:15:00','BILLING','AMOUNT_DUE',500,500,0,100.0,'PASS',NULL),
('RES-024','DQR-025','2025-01-15 08:15:00','BILLING','DUE_DATE',500,475,25,95.0,'FAIL','25 records where due_date < invoice_date'),
('RES-025','DQR-039','2025-01-15 08:15:00','BILLING','OUTSTANDING_BALANCE',500,500,0,100.0,'PASS',NULL),
('RES-026','DQR-028','2025-01-15 08:20:00','AT_RISK_POLICIES','RISK_SCORE',165,165,0,100.0,'PASS',NULL),
('RES-027','DQR-029','2025-01-15 08:20:00','AT_RISK_POLICIES','REVENUE_AT_RISK',165,165,0,100.0,'PASS',NULL),
('RES-028','DQR-042','2025-01-15 08:20:00','AT_RISK_POLICIES','DAYS_SINCE_CONTACT',165,155,10,93.9,'FAIL','10 records with DAYS_SINCE_CONTACT = 0 or negative'),
-- Jan 8 execution (previous week for comparison)
('RES-029','DQR-001','2025-01-08 08:00:00','CUSTOMERS','CUSTOMER_ID',200,200,0,100.0,'PASS',NULL),
('RES-030','DQR-005','2025-01-08 08:00:00','CUSTOMERS','EMAIL',200,194,6,97.0,'PASS','6 malformed emails'),
('RES-031','DQR-011','2025-01-08 08:00:00','CUSTOMERS','STATE',200,190,10,95.0,'PASS','10 non-standard codes'),
('RES-032','DQR-027','2025-01-08 08:00:00','CUSTOMERS','ZIP_CODE',200,185,15,92.5,'FAIL','15 invalid zip codes'),
('RES-033','DQR-013','2025-01-08 08:05:00','POLICIES','COVERAGE_AMOUNT',300,292,8,97.3,'PASS','8 coverage issues'),
('RES-034','DQR-048','2025-01-08 08:05:00','POLICIES','CUSTOMER_ID',300,290,10,96.7,'PASS','10 orphan references'),
('RES-035','DQR-009','2025-01-08 08:10:00','CLAIMS','RESOLUTION_DATE',400,392,8,98.0,'PASS','8 date logic issues'),
('RES-036','DQR-032','2025-01-08 08:10:00','CLAIMS','APPROVED_AMOUNT',400,385,15,96.3,'FAIL','15 over-approved claims'),
('RES-037','DQR-049','2025-01-08 08:10:00','CLAIMS','POLICY_ID',400,378,22,94.5,'FAIL','22 orphan claim references'),
('RES-038','DQR-025','2025-01-08 08:15:00','BILLING','DUE_DATE',500,488,12,97.6,'PASS','12 date logic issues'),
-- Jan 1 baseline
('RES-039','DQR-001','2025-01-01 08:00:00','CUSTOMERS','CUSTOMER_ID',200,200,0,100.0,'PASS',NULL),
('RES-040','DQR-005','2025-01-01 08:00:00','CUSTOMERS','EMAIL',200,196,4,98.0,'PASS','4 malformed emails');


-- ############################################################################
-- SECTION 2: DQ_COLUMN_HEALTH (28 rows - Column-Level Health)
-- ############################################################################

INSERT INTO INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH
(HEALTH_ID, TABLE_NAME, COLUMN_NAME, CHECK_DATE, NULL_PCT, DISTINCT_COUNT, DUPLICATE_PCT, OUTLIER_COUNT, FORMAT_VIOLATION_COUNT, HEALTH_STATUS, SCORE, IS_CRITICAL)
VALUES
-- CUSTOMERS columns
('CH-001','CUSTOMERS','CUSTOMER_ID','2025-01-15',0.0,200,0.0,0,0,'Healthy',100.0,TRUE),
('CH-002','CUSTOMERS','EMAIL','2025-01-15',0.0,188,6.0,0,8,'Warning',88.0,FALSE),
('CH-003','CUSTOMERS','CREDIT_SCORE','2025-01-15',0.0,150,0.0,5,0,'Warning',92.0,FALSE),
('CH-004','CUSTOMERS','STATE','2025-01-15',0.0,12,0.0,0,20,'Critical',72.0,TRUE),
('CH-005','CUSTOMERS','PHONE','2025-01-15',0.0,200,0.0,0,40,'Critical',65.0,FALSE),
('CH-006','CUSTOMERS','ZIP_CODE','2025-01-15',0.0,180,0.0,0,30,'Critical',70.0,FALSE),
('CH-007','CUSTOMERS','DATE_OF_BIRTH','2025-01-15',7.5,185,0.0,3,0,'Warning',85.0,FALSE),
('CH-008','CUSTOMERS','FIRST_NAME','2025-01-15',1.0,45,0.0,0,0,'Healthy',98.0,TRUE),
('CH-009','CUSTOMERS','LAST_NAME','2025-01-15',0.0,38,0.0,0,0,'Healthy',100.0,TRUE),
('CH-010','CUSTOMERS','RISK_TIER','2025-01-15',0.0,4,0.0,0,0,'Healthy',100.0,FALSE),
-- POLICIES columns
('CH-011','POLICIES','POLICY_ID','2025-01-15',0.0,300,0.0,0,0,'Healthy',100.0,TRUE),
('CH-012','POLICIES','CUSTOMER_ID','2025-01-15',0.0,180,0.0,0,0,'Warning',93.3,TRUE),
('CH-013','POLICIES','PREMIUM_AMOUNT','2025-01-15',0.0,285,0.0,2,0,'Healthy',99.3,TRUE),
('CH-014','POLICIES','COVERAGE_AMOUNT','2025-01-15',0.0,290,0.0,15,0,'Warning',95.0,TRUE),
('CH-015','POLICIES','LOSS_RATIO','2025-01-15',0.0,275,0.0,0,0,'Healthy',100.0,FALSE),
-- CLAIMS columns
('CH-016','CLAIMS','CLAIM_ID','2025-01-15',0.0,400,0.0,0,0,'Healthy',100.0,TRUE),
('CH-017','CLAIMS','POLICY_ID','2025-01-15',0.0,250,0.0,0,0,'Critical',90.0,TRUE),
('CH-018','CLAIMS','CLAIM_AMOUNT','2025-01-15',0.0,380,0.0,8,0,'Healthy',98.0,TRUE),
('CH-019','CLAIMS','APPROVED_AMOUNT','2025-01-15',45.0,120,0.0,30,0,'Critical',72.5,TRUE),
('CH-020','CLAIMS','RESOLUTION_DATE','2025-01-15',50.0,85,0.0,0,15,'Warning',80.0,FALSE),
('CH-021','CLAIMS','FRAUD_SCORE','2025-01-15',0.0,95,0.0,0,0,'Healthy',100.0,FALSE),
-- BILLING columns
('CH-022','BILLING','AMOUNT_DUE','2025-01-15',0.0,420,0.0,0,0,'Healthy',100.0,TRUE),
('CH-023','BILLING','DUE_DATE','2025-01-15',0.0,150,0.0,0,25,'Warning',95.0,TRUE),
('CH-024','BILLING','OUTSTANDING_BALANCE','2025-01-15',0.0,380,0.0,0,0,'Healthy',100.0,TRUE),
-- AT_RISK_POLICIES columns
('CH-025','AT_RISK_POLICIES','RISK_SCORE','2025-01-15',0.0,160,0.0,0,0,'Healthy',100.0,FALSE),
('CH-026','AT_RISK_POLICIES','REVENUE_AT_RISK','2025-01-15',0.0,165,0.0,0,0,'Healthy',100.0,TRUE),
('CH-027','AT_RISK_POLICIES','DAYS_SINCE_CONTACT','2025-01-15',0.0,100,0.0,10,0,'Warning',93.9,FALSE),
('CH-028','AT_RISK_POLICIES','CHURN_PROBABILITY','2025-01-15',0.0,155,0.0,0,0,'Healthy',100.0,FALSE);


-- ============================================================================
-- END OF DML PART 3
-- ============================================================================
