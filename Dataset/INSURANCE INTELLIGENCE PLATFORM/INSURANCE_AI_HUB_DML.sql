-- ============================================================================
-- INSURANCE AI HUB - Complete DML Script (All 12 Tables)
-- Database: INSURANCE_AI_HUB
-- Run this AFTER the DDL script (INSURANCE_AI_HUB_DDL_DML.sql)
-- ============================================================================


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
