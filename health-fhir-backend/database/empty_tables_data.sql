-- ===========================================
-- DATA FOR EMPTY TABLES
-- ===========================================

-- DAK CONTACT SCHEDULE DATA (Patient contact scheduling)
INSERT INTO dak_contact_schedule (fhir_id, patient_id, pregnancy_id, contact_number, recommended_gestation_weeks, contact_date, contact_status, provider_notes, dak_contact_id, contact_type, fhir_resource, version_id) VALUES
('dak-cs-001', 1, 1, 1, 8, '2024-07-22', 'completed', 'Follow-up call after first ANC visit', 'DAK-CS-001', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-001"}', '1'),
('dak-cs-002', 1, 1, 2, 12, '2024-08-05', 'completed', 'Reminder for second ANC visit', 'DAK-CS-002', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-002"}', '1'),
('dak-cs-003', 1, 1, 3, 16, '2024-08-19', 'completed', 'Follow-up call after second ANC visit', 'DAK-CS-003', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-003"}', '1'),
('dak-cs-004', 1, 1, 4, 20, '2024-09-02', 'completed', 'Reminder for third ANC visit', 'DAK-CS-004', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-004"}', '1'),
('dak-cs-005', 1, 1, 5, 24, '2024-09-16', 'completed', 'Follow-up call after third ANC visit', 'DAK-CS-005', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-005"}', '1'),
('dak-cs-006', 1, 1, 6, 28, '2024-09-30', 'completed', 'Reminder for fourth ANC visit', 'DAK-CS-006', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-006"}', '1'),
('dak-cs-007', 1, 1, 7, 32, '2024-10-14', 'completed', 'Follow-up call after fourth ANC visit - BP monitoring', 'DAK-CS-007', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-007"}', '1'),
('dak-cs-008', 1, 1, 8, 36, '2024-10-28', 'completed', 'Reminder for fifth ANC visit', 'DAK-CS-008', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-008"}', '1'),
('dak-cs-009', 1, 1, 9, 40, '2024-11-11', 'completed', 'Follow-up call after fifth ANC visit', 'DAK-CS-009', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-009"}', '1'),
('dak-cs-010', 1, 1, 10, 44, '2024-11-18', 'completed', 'Reminder for sixth ANC visit', 'DAK-CS-010', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-010"}', '1'),
('dak-cs-011', 1, 1, 11, 48, '2024-12-02', 'completed', 'Follow-up call after sixth ANC visit - edema noted', 'DAK-CS-011', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-011"}', '1'),
('dak-cs-012', 1, 1, 12, 52, '2024-12-09', 'completed', 'Reminder for seventh ANC visit', 'DAK-CS-012', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-012"}', '1'),
('dak-cs-013', 1, 1, 13, 56, '2024-12-23', 'completed', 'Follow-up call after seventh ANC visit - edema management', 'DAK-CS-013', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-013"}', '1'),
('dak-cs-014', 1, 1, 14, 60, '2024-12-30', 'completed', 'Reminder for eighth ANC visit', 'DAK-CS-014', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-014"}', '1'),
('dak-cs-015', 1, 1, 15, 64, '2025-01-13', 'completed', 'Follow-up call after eighth ANC visit - severe edema', 'DAK-CS-015', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-015"}', '1'),
('dak-cs-016', 1, 1, 16, 68, '2025-01-20', 'completed', 'Reminder for ninth ANC visit', 'DAK-CS-016', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-016"}', '1'),
('dak-cs-017', 1, 1, 17, 72, '2025-02-03', 'completed', 'Follow-up call after ninth ANC visit - delivery preparation', 'DAK-CS-017', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-017"}', '1'),
('dak-cs-018', 1, 1, 18, 76, '2025-02-10', 'completed', 'Reminder for delivery date', 'DAK-CS-018', 'ANC', '{"resourceType": "Communication", "id": "dak-cs-018"}', '1'),
('dak-cs-019', 1, 1, 19, 80, '2025-02-24', 'completed', 'Follow-up call after delivery - postnatal care', 'DAK-CS-019', 'PNC', '{"resourceType": "Communication", "id": "dak-cs-019"}', '1'),
('dak-cs-020', 1, 1, 20, 84, '2025-03-03', 'completed', 'Follow-up call for postnatal care visit', 'DAK-CS-020', 'PNC', '{"resourceType": "Communication", "id": "dak-cs-020"}', '1');

-- DAK RISK ASSESSMENT DATA (Risk assessments)
INSERT INTO dak_risk_assessment (fhir_id, patient_id, encounter_id, risk_category, risk_factors, risk_score, risk_level, management_plan, follow_up_required, dak_risk_id, assessment_date, assessor_name, fhir_resource, version_id) VALUES
('dak-ra-001', 1, 1, 'maternal', 'First pregnancy, no previous complications', 2, 'low', 'Continue routine ANC care', TRUE, 'DAK-RA-001', '2024-07-15', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-001"}', '1'),
('dak-ra-002', 1, 2, 'maternal', 'No new risk factors identified', 2, 'low', 'Continue routine ANC care', TRUE, 'DAK-RA-002', '2024-08-12', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-002"}', '1'),
('dak-ra-003', 1, 3, 'maternal', 'No new risk factors identified', 2, 'low', 'Continue routine ANC care', TRUE, 'DAK-RA-003', '2024-09-09', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-003"}', '1'),
('dak-ra-004', 1, 4, 'maternal', 'Elevated blood pressure noted', 4, 'medium', 'Monitor blood pressure closely, consider lifestyle modifications', TRUE, 'DAK-RA-004', '2024-10-07', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-004"}', '1'),
('dak-ra-005', 1, 5, 'maternal', 'Blood pressure at upper limit, continue monitoring', 4, 'medium', 'Continue BP monitoring, dietary counseling', TRUE, 'DAK-RA-005', '2024-11-04', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-005"}', '1'),
('dak-ra-006', 1, 6, 'maternal', 'Mild ankle edema noted', 5, 'medium', 'Monitor edema progression, elevate legs, compression stockings', TRUE, 'DAK-RA-006', '2024-11-25', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-006"}', '1'),
('dak-ra-007', 1, 7, 'maternal', 'Moderate ankle edema, BP still elevated', 6, 'medium', 'Continue edema management, consider diuretics if severe', TRUE, 'DAK-RA-007', '2024-12-16', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-007"}', '1'),
('dak-ra-008', 1, 8, 'maternal', 'Persistent moderate edema', 6, 'medium', 'Continue current management, monitor for preeclampsia signs', TRUE, 'DAK-RA-008', '2025-01-06', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-008"}', '1'),
('dak-ra-009', 1, 9, 'maternal', 'Severe ankle edema, elevated BP', 8, 'high', 'Consider hospitalization, diuretic therapy, close monitoring', TRUE, 'DAK-RA-009', '2025-01-27', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-009"}', '1'),
('dak-ra-010', 1, 10, 'maternal', 'Severe edema, BP elevated, delivery approaching', 8, 'high', 'Prepare for delivery, consider early induction if needed', TRUE, 'DAK-RA-010', '2025-02-03', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-010"}', '1'),
('dak-ra-011', 1, 10, 'maternal', 'Successful delivery, no complications', 1, 'low', 'Continue postnatal care, monitor recovery', TRUE, 'DAK-RA-011', '2025-02-17', 'Dr. Sarah Johnson', '{"resourceType": "RiskAssessment", "id": "dak-ra-011"}', '1');

-- DAK QUALITY INDICATORS DATA (Quality metrics)
INSERT INTO dak_quality_indicators (fhir_id, organization_id, indicator_name, indicator_code, indicator_category, target_value, actual_value, measurement_date, measurement_period_start, measurement_period_end, status, description, fhir_resource, version_id) VALUES
('dak-qi-001', 1, 'ANC Coverage Rate', 'ANC_COV_001', 'coverage', 90.0, 95.2, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of pregnant women receiving at least 4 ANC visits', '{"resourceType": "Measure", "id": "dak-qi-001"}', '1'),
('dak-qi-002', 1, 'Skilled Birth Attendance', 'SBA_001', 'coverage', 85.0, 88.7, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of deliveries attended by skilled health personnel', '{"resourceType": "Measure", "id": "dak-qi-002"}', '1'),
('dak-qi-003', 1, 'Postnatal Care Coverage', 'PNC_COV_001', 'coverage', 80.0, 82.3, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of women receiving postnatal care within 48 hours', '{"resourceType": "Measure", "id": "dak-qi-003"}', '1'),
('dak-qi-004', 1, 'Iron Supplementation Coverage', 'IRON_SUPP_001', 'coverage', 95.0, 97.1, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of pregnant women receiving iron supplementation', '{"resourceType": "Measure", "id": "dak-qi-004"}', '1'),
('dak-qi-005', 1, 'Folic Acid Supplementation', 'FOLIC_ACID_001', 'coverage', 90.0, 93.8, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of pregnant women receiving folic acid supplementation', '{"resourceType": "Measure", "id": "dak-qi-005"}', '1'),
('dak-qi-006', 1, 'HIV Testing Coverage', 'HIV_TEST_001', 'coverage', 95.0, 96.5, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of pregnant women tested for HIV', '{"resourceType": "Measure", "id": "dak-qi-006"}', '1'),
('dak-qi-007', 1, 'Syphilis Testing Coverage', 'SYPH_TEST_001', 'coverage', 90.0, 91.2, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of pregnant women tested for syphilis', '{"resourceType": "Measure", "id": "dak-qi-007"}', '1'),
('dak-qi-008', 1, 'Tetanus Toxoid Coverage', 'TT_COV_001', 'coverage', 85.0, 87.9, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Percentage of pregnant women receiving tetanus toxoid vaccination', '{"resourceType": "Measure", "id": "dak-qi-008"}', '1'),
('dak-qi-009', 1, 'Maternal Mortality Ratio', 'MMR_001', 'outcome', 5.0, 3.2, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Maternal deaths per 100,000 live births', '{"resourceType": "Measure", "id": "dak-qi-009"}', '1'),
('dak-qi-010', 1, 'Stillbirth Rate', 'SB_RATE_001', 'outcome', 2.0, 1.8, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Stillbirths per 1000 total births', '{"resourceType": "Measure", "id": "dak-qi-010"}', '1'),
('dak-qi-011', 1, 'Early Neonatal Death Rate', 'END_RATE_001', 'outcome', 3.0, 2.5, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Early neonatal deaths per 1000 live births', '{"resourceType": "Measure", "id": "dak-qi-011"}', '1'),
('dak-qi-012', 1, 'Low Birth Weight Rate', 'LBW_RATE_001', 'outcome', 10.0, 8.7, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Low birth weight babies per 100 live births', '{"resourceType": "Measure", "id": "dak-qi-012"}', '1'),
('dak-qi-013', 1, 'Preterm Birth Rate', 'PTB_RATE_001', 'outcome', 8.0, 6.9, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Preterm births per 100 live births', '{"resourceType": "Measure", "id": "dak-qi-013"}', '1'),
('dak-qi-014', 1, 'Caesarean Section Rate', 'CS_RATE_001', 'outcome', 15.0, 12.3, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Caesarean sections per 100 live births', '{"resourceType": "Measure", "id": "dak-qi-014"}', '1'),
('dak-qi-015', 1, 'Eclampsia Rate', 'ECL_RATE_001', 'outcome', 1.0, 0.8, '2024-12-31', '2024-01-01', '2024-12-31', 'achieved', 'Eclampsia cases per 1000 deliveries', '{"resourceType": "Measure", "id": "dak-qi-015"}', '1');

-- ===========================================
-- END OF EMPTY TABLES DATA
-- ===========================================
