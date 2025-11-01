-- ===========================================
-- FINAL EMPTY TABLES DATA
-- ===========================================

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
INSERT INTO dak_quality_indicators (fhir_id, patient_id, encounter_id, indicator_code, indicator_name, indicator_value, indicator_status, risk_flag, decision_support_message, next_visit_schedule, dak_indicator_id, measurement_date, target_value, fhir_resource, version_id) VALUES
('dak-qi-001', 1, 1, 'ANC_COV_001', 'ANC Coverage Rate', '95.2%', 'completed', 'no', 'Patient has completed 8 ANC visits, exceeding target', '2024-08-12', 'DAK-QI-001', '2024-07-15', '90.0%', '{"resourceType": "Measure", "id": "dak-qi-001"}', '1'),
('dak-qi-002', 1, 2, 'SBA_001', 'Skilled Birth Attendance', '100%', 'completed', 'no', 'Delivery attended by skilled health personnel', '2024-09-09', 'DAK-QI-002', '2024-08-12', '85.0%', '{"resourceType": "Measure", "id": "dak-qi-002"}', '1'),
('dak-qi-003', 1, 3, 'PNC_COV_001', 'Postnatal Care Coverage', '100%', 'completed', 'no', 'Postnatal care provided within 48 hours', '2024-10-07', 'DAK-QI-003', '2024-09-09', '80.0%', '{"resourceType": "Measure", "id": "dak-qi-003"}', '1'),
('dak-qi-004', 1, 4, 'IRON_SUPP_001', 'Iron Supplementation Coverage', '100%', 'completed', 'no', 'Iron supplementation provided throughout pregnancy', '2024-11-04', 'DAK-QI-004', '2024-10-07', '95.0%', '{"resourceType": "Measure", "id": "dak-qi-004"}', '1'),
('dak-qi-005', 1, 5, 'FOLIC_ACID_001', 'Folic Acid Supplementation', '100%', 'completed', 'no', 'Folic acid supplementation provided throughout pregnancy', '2024-11-25', 'DAK-QI-005', '2024-11-04', '90.0%', '{"resourceType": "Measure", "id": "dak-qi-005"}', '1'),
('dak-qi-006', 1, 6, 'HIV_TEST_001', 'HIV Testing Coverage', '100%', 'completed', 'no', 'HIV testing completed with negative result', '2024-12-16', 'DAK-QI-006', '2024-11-25', '95.0%', '{"resourceType": "Measure", "id": "dak-qi-006"}', '1'),
('dak-qi-007', 1, 7, 'SYPH_TEST_001', 'Syphilis Testing Coverage', '100%', 'completed', 'no', 'Syphilis testing completed with negative result', '2025-01-06', 'DAK-QI-007', '2024-12-16', '90.0%', '{"resourceType": "Measure", "id": "dak-qi-007"}', '1'),
('dak-qi-008', 1, 8, 'TT_COV_001', 'Tetanus Toxoid Coverage', '100%', 'completed', 'no', 'Tetanus toxoid vaccination completed', '2025-01-27', 'DAK-QI-008', '2025-01-06', '85.0%', '{"resourceType": "Measure", "id": "dak-qi-008"}', '1'),
('dak-qi-009', 1, 9, 'MMR_001', 'Maternal Mortality Ratio', '0', 'completed', 'no', 'No maternal mortality recorded', '2025-02-03', 'DAK-QI-009', '2025-01-27', '5.0', '{"resourceType": "Measure", "id": "dak-qi-009"}', '1'),
('dak-qi-010', 1, 10, 'SB_RATE_001', 'Stillbirth Rate', '0', 'completed', 'no', 'No stillbirths recorded', '2025-02-17', 'DAK-QI-010', '2025-02-03', '2.0', '{"resourceType": "Measure", "id": "dak-qi-010"}', '1'),
('dak-qi-011', 1, 10, 'END_RATE_001', 'Early Neonatal Death Rate', '0', 'completed', 'no', 'No early neonatal deaths recorded', '2025-02-17', 'DAK-QI-011', '2025-02-17', '3.0', '{"resourceType": "Measure", "id": "dak-qi-011"}', '1'),
('dak-qi-012', 1, 10, 'LBW_RATE_001', 'Low Birth Weight Rate', '0', 'completed', 'no', 'Normal birth weight achieved', '2025-02-17', 'DAK-QI-012', '2025-02-17', '10.0', '{"resourceType": "Measure", "id": "dak-qi-012"}', '1'),
('dak-qi-013', 1, 10, 'PTB_RATE_001', 'Preterm Birth Rate', '0', 'completed', 'no', 'Full-term delivery achieved', '2025-02-17', 'DAK-QI-013', '2025-02-17', '8.0', '{"resourceType": "Measure", "id": "dak-qi-013"}', '1'),
('dak-qi-014', 1, 10, 'CS_RATE_001', 'Caesarean Section Rate', '0', 'completed', 'no', 'Normal vaginal delivery achieved', '2025-02-17', 'DAK-QI-014', '2025-02-17', '15.0', '{"resourceType": "Measure", "id": "dak-qi-014"}', '1'),
('dak-qi-015', 1, 10, 'ECL_RATE_001', 'Eclampsia Rate', '0', 'completed', 'no', 'No eclampsia recorded', '2025-02-17', 'DAK-QI-015', '2025-02-17', '1.0', '{"resourceType": "Measure", "id": "dak-qi-015"}', '1');

-- ===========================================
-- END OF FINAL EMPTY TABLES DATA
-- ===========================================
