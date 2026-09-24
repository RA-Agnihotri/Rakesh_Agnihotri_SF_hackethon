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
