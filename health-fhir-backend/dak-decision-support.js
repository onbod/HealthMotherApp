/**
 * DAK (Digital Adaptation Kit) Decision Support System
 * Implements complete ANC decision tree (ANC.DT.01-14) and scheduling logic (ANC.S.01-05)
 * Based on WHO Digital Adaptation Kit for Antenatal Care
 */

// DAK Decision Points Configuration
const DAK_DECISION_POINTS = {
  'ANC.DT.01': {
    name: 'Danger Signs Assessment',
    description: 'Assess for danger signs requiring immediate referral',
    conditions: ['vaginal_bleeding', 'severe_headache', 'blurred_vision', 'severe_abdominal_pain', 'fever', 'difficulty_breathing'],
    action: 'immediate_referral',
    priority: 'high'
  },
  'ANC.DT.02': {
    name: 'Blood Pressure Assessment',
    description: 'Assess blood pressure for pre-eclampsia risk',
    conditions: ['systolic_bp', 'diastolic_bp'],
    thresholds: { systolic: 140, diastolic: 90 },
    action: 'referral_if_high',
    priority: 'high'
  },
  'ANC.DT.03': {
    name: 'Proteinuria Testing',
    description: 'Test for protein in urine',
    conditions: ['urine_protein'],
    thresholds: { protein: 'positive' },
    action: 'referral_if_positive',
    priority: 'high'
  },
  'ANC.DT.04': {
    name: 'Anemia Screening',
    description: 'Screen for anemia using hemoglobin levels',
    conditions: ['haemoglobin'],
    thresholds: { hemoglobin: 11.0 },
    action: 'iron_supplementation',
    priority: 'medium'
  },
  'ANC.DT.05': {
    name: 'HIV Testing and Counseling',
    description: 'Offer HIV testing and counseling',
    conditions: ['hiv_status'],
    action: 'counseling_and_testing',
    priority: 'high'
  },
  'ANC.DT.06': {
    name: 'Syphilis Screening',
    description: 'Screen for syphilis infection',
    conditions: ['syphilis_status'],
    action: 'treatment_if_positive',
    priority: 'high'
  },
  'ANC.DT.07': {
    name: 'Malaria Prevention',
    description: 'Provide malaria prevention measures',
    conditions: ['malaria_area', 'gestational_age'],
    action: 'iptp_prophylaxis',
    priority: 'medium'
  },
  'ANC.DT.08': {
    name: 'Tetanus Immunization',
    description: 'Provide tetanus toxoid vaccination',
    conditions: ['tetanus_doses'],
    thresholds: { doses_needed: 2 },
    action: 'vaccination',
    priority: 'medium'
  },
  'ANC.DT.09': {
    name: 'Iron Supplementation',
    description: 'Provide iron and folic acid supplementation',
    conditions: ['iron_supplementation'],
    action: 'supplementation',
    priority: 'medium'
  },
  'ANC.DT.10': {
    name: 'Birth Preparedness',
    description: 'Counsel on birth preparedness and complication readiness',
    conditions: ['birth_plan', 'emergency_plan'],
    action: 'counseling',
    priority: 'medium'
  },
  'ANC.DT.11': {
    name: 'Emergency Planning',
    description: 'Develop emergency plan for complications',
    conditions: ['emergency_contacts', 'transport_plan'],
    action: 'planning',
    priority: 'medium'
  },
  'ANC.DT.12': {
    name: 'Postpartum Care Planning',
    description: 'Plan for postpartum care and family planning',
    conditions: ['postpartum_plan', 'family_planning'],
    action: 'planning',
    priority: 'low'
  },
  'ANC.DT.13': {
    name: 'Family Planning Counseling',
    description: 'Provide family planning counseling',
    conditions: ['family_planning_method'],
    action: 'counseling',
    priority: 'low'
  },
  'ANC.DT.14': {
    name: 'Danger Sign Recognition',
    description: 'Educate on danger sign recognition',
    conditions: ['danger_sign_education'],
    action: 'education',
    priority: 'medium'
  }
};

// DAK Scheduling Guidelines (ANC.S.01-05)
const DAK_SCHEDULING = {
  'ANC.S.01': {
    name: 'First ANC Visit',
    gestational_age_range: { min: 8, max: 12 },
    priority: 'high',
    required_assessments: ['ANC.DT.01', 'ANC.DT.02', 'ANC.DT.04', 'ANC.DT.05', 'ANC.DT.06']
  },
  'ANC.S.02': {
    name: 'Second ANC Visit',
    gestational_age_range: { min: 20, max: 24 },
    priority: 'high',
    required_assessments: ['ANC.DT.01', 'ANC.DT.02', 'ANC.DT.03', 'ANC.DT.04', 'ANC.DT.07', 'ANC.DT.08']
  },
  'ANC.S.03': {
    name: 'Third ANC Visit',
    gestational_age_range: { min: 26, max: 30 },
    priority: 'high',
    required_assessments: ['ANC.DT.01', 'ANC.DT.02', 'ANC.DT.03', 'ANC.DT.04', 'ANC.DT.07']
  },
  'ANC.S.04': {
    name: 'Fourth ANC Visit',
    gestational_age_range: { min: 32, max: 36 },
    priority: 'high',
    required_assessments: ['ANC.DT.01', 'ANC.DT.02', 'ANC.DT.03', 'ANC.DT.04', 'ANC.DT.10', 'ANC.DT.11']
  },
  'ANC.S.05': {
    name: 'Fifth ANC Visit',
    gestational_age_range: { min: 38, max: 40 },
    priority: 'medium',
    required_assessments: ['ANC.DT.01', 'ANC.DT.02', 'ANC.DT.03', 'ANC.DT.12', 'ANC.DT.13']
  }
};

// DAK Indicators Configuration
const DAK_INDICATORS = {
  'ANC.IND.01': {
    name: 'Early ANC Initiation',
    description: 'Percentage of women who initiated ANC before 12 weeks',
    numerator: 'Women with first ANC visit before 12 weeks',
    denominator: 'Total women with ANC visits',
    target: 80
  },
  'ANC.IND.02': {
    name: 'Four or More ANC Visits',
    description: 'Percentage of women with 4 or more ANC visits',
    numerator: 'Women with ≥4 ANC visits',
    denominator: 'Total women with ANC visits',
    target: 90
  },
  'ANC.IND.03': {
    name: 'Quality ANC Visits',
    description: 'Percentage of ANC visits with comprehensive care',
    numerator: 'ANC visits with all required assessments',
    denominator: 'Total ANC visits',
    target: 85
  },
  'ANC.IND.04': {
    name: 'HIV Testing Coverage',
    description: 'Percentage of women tested for HIV during ANC',
    numerator: 'Women tested for HIV',
    denominator: 'Total women with ANC visits',
    target: 95
  },
  'ANC.IND.05': {
    name: 'Syphilis Screening Coverage',
    description: 'Percentage of women screened for syphilis',
    numerator: 'Women screened for syphilis',
    denominator: 'Total women with ANC visits',
    target: 90
  },
  'ANC.IND.06': {
    name: 'Iron Supplementation Coverage',
    description: 'Percentage of women receiving iron supplementation',
    numerator: 'Women receiving iron supplementation',
    denominator: 'Total women with ANC visits',
    target: 90
  },
  'ANC.IND.07': {
    name: 'Tetanus Immunization Coverage',
    description: 'Percentage of women receiving tetanus immunization',
    numerator: 'Women receiving tetanus immunization',
    denominator: 'Total women with ANC visits',
    target: 90
  },
  'ANC.IND.08': {
    name: 'Birth Preparedness Planning',
    description: 'Percentage of women with birth preparedness plan',
    numerator: 'Women with birth preparedness plan',
    denominator: 'Total women with ANC visits',
    target: 80
  },
  'ANC.IND.09': {
    name: 'Danger Sign Recognition',
    description: 'Percentage of women educated on danger signs',
    numerator: 'Women educated on danger signs',
    denominator: 'Total women with ANC visits',
    target: 85
  },
  'ANC.IND.10': {
    name: 'Postpartum Care Planning',
    description: 'Percentage of women with postpartum care plan',
    numerator: 'Women with postpartum care plan',
    denominator: 'Total women with ANC visits',
    target: 75
  }
};

/**
 * Generate comprehensive DAK decision support alerts
 * @param {Object} pregnancy - Pregnancy data
 * @param {Array} ancVisits - Array of ANC visit data
 * @returns {Array} Array of decision support alerts
 */
function generateDAKDecisionSupportAlerts(pregnancy, ancVisits) {
  const alerts = [];
  const decisionLog = [];

  ancVisits.forEach(visit => {
    // ANC.DT.01: Danger Signs Assessment
    if (visit.danger_signs_present === true) {
      // Parse danger signs list if it's a string, or use as array if already parsed
      let dangerSigns = [];
      if (visit.danger_signs_list) {
        if (typeof visit.danger_signs_list === 'string') {
          try {
            dangerSigns = JSON.parse(visit.danger_signs_list);
          } catch (e) {
            // If not JSON, treat as comma-separated string
            dangerSigns = visit.danger_signs_list.split(',').map(s => s.trim());
          }
        } else if (Array.isArray(visit.danger_signs_list)) {
          dangerSigns = visit.danger_signs_list;
        }
      }
      
      if (dangerSigns.length > 0) {
        dangerSigns.forEach(sign => {
          alerts.push({
            code: `DAK.ANC.DT.01.${sign.toUpperCase().replace(/\s+/g, '_')}`,
            message: `Danger sign detected: ${sign} - Immediate referral required`,
            priority: 'high',
            action: 'immediate_referral',
            decisionPoint: 'ANC.DT.01',
            visitId: visit.anc_visit_id,
            visitNumber: visit.visit_number
          });
        });
      } else {
        // If danger signs present but list is empty, still alert
        alerts.push({
          code: 'DAK.ANC.DT.01.DANGER_SIGNS',
          message: 'Danger signs detected - Immediate referral required',
          priority: 'high',
          action: 'immediate_referral',
          decisionPoint: 'ANC.DT.01',
          visitId: visit.anc_visit_id,
          visitNumber: visit.visit_number
        });
      }
    }

    // ANC.DT.02: Blood Pressure Assessment
    if (visit.blood_pressure_systolic && visit.blood_pressure_diastolic) {
      if (visit.blood_pressure_systolic >= 140 || visit.blood_pressure_diastolic >= 90) {
        alerts.push({
          code: 'DAK.ANC.DT.02.HYPERTENSION',
          message: `High blood pressure detected (${visit.blood_pressure_systolic}/${visit.blood_pressure_diastolic}) - Pre-eclampsia risk`,
          priority: 'high',
          action: 'referral_if_high',
          decisionPoint: 'ANC.DT.02',
          visitId: visit.anc_visit_id,
          visitNumber: visit.visit_number
        });
      }
    }

    // ANC.DT.03: Proteinuria Testing
    if (visit.urine_protein === 'positive' || visit.urine_protein === '+') {
      alerts.push({
        code: 'DAK.ANC.DT.03.PROTEINURIA',
        message: 'Proteinuria detected - Pre-eclampsia risk',
        priority: 'high',
        action: 'referral_if_positive',
        decisionPoint: 'ANC.DT.03',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.04: Anemia Screening
    if (visit.hemoglobin_gdl && visit.hemoglobin_gdl < 11.0) {
      alerts.push({
        code: 'DAK.ANC.DT.04.ANEMIA',
        message: `Anemia detected (Hb: ${visit.hemoglobin_gdl}g/dL) - Iron supplementation needed`,
        priority: 'medium',
        action: 'iron_supplementation',
        decisionPoint: 'ANC.DT.04',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.05: HIV Testing
    if (!visit.hiv_test_done || (visit.hiv_test_result && visit.hiv_test_result === 'pending')) {
      alerts.push({
        code: 'DAK.ANC.DT.05.HIV_NOT_TESTED',
        message: 'HIV testing not completed - Offer testing and counseling',
        priority: 'high',
        action: 'counseling_and_testing',
        decisionPoint: 'ANC.DT.05',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.06: Syphilis Screening
    if (!visit.syphilis_test_done || (visit.syphilis_test_result && visit.syphilis_test_result === 'pending')) {
      alerts.push({
        code: 'DAK.ANC.DT.06.SYPHILIS_NOT_TESTED',
        message: 'Syphilis screening not completed - Offer screening',
        priority: 'high',
        action: 'treatment_if_positive',
        decisionPoint: 'ANC.DT.06',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.07: Malaria Prevention
    const gestationWeeks = visit.gestation_weeks || 0;
    if (gestationWeeks >= 13 && !visit.malaria_prophylaxis_given) {
      alerts.push({
        code: 'DAK.ANC.DT.07.MALARIA_PREVENTION',
        message: 'Malaria prevention incomplete - Provide IPTp prophylaxis',
        priority: 'medium',
        action: 'iptp_prophylaxis',
        decisionPoint: 'ANC.DT.07',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.08: Tetanus Immunization
    if (!visit.tetanus_toxoid_given || !visit.tetanus_toxoid_dose || visit.tetanus_toxoid_dose < 2) {
      alerts.push({
        code: 'DAK.ANC.DT.08.TETANUS_INCOMPLETE',
        message: 'Tetanus immunization incomplete - Provide vaccination',
        priority: 'medium',
        action: 'vaccination',
        decisionPoint: 'ANC.DT.08',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.09: Iron Supplementation
    if (!visit.iron_supplement_given || visit.iron_supplement_given === false) {
      alerts.push({
        code: 'DAK.ANC.DT.09.IRON_SUPPLEMENTATION',
        message: 'Iron supplementation not provided - Provide iron and folic acid',
        priority: 'medium',
        action: 'supplementation',
        decisionPoint: 'ANC.DT.09',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.10: Birth Preparedness
    // Note: birth_preparedness_plan field may not exist in schema, checking plan_of_care instead
    if (!visit.plan_of_care || (visit.plan_of_care && !visit.plan_of_care.toLowerCase().includes('birth'))) {
      alerts.push({
        code: 'DAK.ANC.DT.10.BIRTH_PREPAREDNESS',
        message: 'Birth preparedness planning not completed - Provide counseling',
        priority: 'medium',
        action: 'counseling',
        decisionPoint: 'ANC.DT.10',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.11: Emergency Planning
    // Note: emergency_plan field may not exist in schema, checking plan_of_care instead
    if (!visit.plan_of_care || (visit.plan_of_care && !visit.plan_of_care.toLowerCase().includes('emergency'))) {
      alerts.push({
        code: 'DAK.ANC.DT.11.EMERGENCY_PLANNING',
        message: 'Emergency plan not developed - Develop emergency plan',
        priority: 'medium',
        action: 'planning',
        decisionPoint: 'ANC.DT.11',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.12: Postpartum Care Planning
    // Note: postpartum_plan field may not exist in schema, checking plan_of_care instead
    if (!visit.plan_of_care || (visit.plan_of_care && !visit.plan_of_care.toLowerCase().includes('postpartum'))) {
      alerts.push({
        code: 'DAK.ANC.DT.12.POSTPARTUM_PLANNING',
        message: 'Postpartum care planning not completed - Plan for postpartum care',
        priority: 'low',
        action: 'planning',
        decisionPoint: 'ANC.DT.12',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.13: Family Planning Counseling
    // Note: family_planning_counseling field may not exist in schema, checking provider_notes instead
    if (!visit.provider_notes || (visit.provider_notes && !visit.provider_notes.toLowerCase().includes('family planning'))) {
      alerts.push({
        code: 'DAK.ANC.DT.13.FAMILY_PLANNING',
        message: 'Family planning counseling not provided - Provide counseling',
        priority: 'low',
        action: 'counseling',
        decisionPoint: 'ANC.DT.13',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }

    // ANC.DT.14: Danger Sign Recognition Education
    // Note: danger_sign_education field may not exist in schema, checking provider_notes instead
    if (!visit.provider_notes || (visit.provider_notes && !visit.provider_notes.toLowerCase().includes('danger sign'))) {
      alerts.push({
        code: 'DAK.ANC.DT.14.DANGER_SIGN_EDUCATION',
        message: 'Danger sign recognition education not provided - Provide education',
        priority: 'medium',
        action: 'education',
        decisionPoint: 'ANC.DT.14',
        visitId: visit.anc_visit_id,
        visitNumber: visit.visit_number
      });
    }
  });

  return alerts;
}

/**
 * Calculate next ANC visit based on DAK scheduling guidelines
 * @param {Object} pregnancy - Pregnancy data
 * @param {Array} ancVisits - Array of ANC visit data
 * @returns {Object} Next visit recommendation
 */
function calculateNextDAKVisit(pregnancy, ancVisits) {
  // Use current_gestation_weeks from pregnancy or calculate from last visit
  let currentGestationalAge = pregnancy.current_gestation_weeks || 0;
  if (currentGestationalAge === 0 && ancVisits.length > 0) {
    const lastVisit = ancVisits[ancVisits.length - 1];
    currentGestationalAge = lastVisit.gestation_weeks || 0;
  }
  
  const visitCount = ancVisits.length;
  const lastVisit = ancVisits[ancVisits.length - 1];

  // Determine next visit based on DAK scheduling
  let nextVisitSchedule = null;
  let nextVisitDate = null;
  let nextVisitWeeks = null;

  if (visitCount === 0) {
    // First visit (ANC.S.01)
    nextVisitSchedule = DAK_SCHEDULING['ANC.S.01'];
    nextVisitWeeks = 8; // Earliest recommended
  } else if (visitCount === 1) {
    // Second visit (ANC.S.02)
    nextVisitSchedule = DAK_SCHEDULING['ANC.S.02'];
    nextVisitWeeks = 20;
  } else if (visitCount === 2) {
    // Third visit (ANC.S.03)
    nextVisitSchedule = DAK_SCHEDULING['ANC.S.03'];
    nextVisitWeeks = 26;
  } else if (visitCount === 3) {
    // Fourth visit (ANC.S.04)
    nextVisitSchedule = DAK_SCHEDULING['ANC.S.04'];
    nextVisitWeeks = 32;
  } else if (visitCount === 4) {
    // Fifth visit (ANC.S.05)
    nextVisitSchedule = DAK_SCHEDULING['ANC.S.05'];
    nextVisitWeeks = 38;
  }

  // Calculate next visit date
  if (nextVisitWeeks && pregnancy.lmp_date) {
    const lmpDate = new Date(pregnancy.lmp_date);
    const nextVisitDateObj = new Date(lmpDate);
    nextVisitDateObj.setDate(lmpDate.getDate() + (nextVisitWeeks * 7));
    nextVisitDate = nextVisitDateObj.toISOString().split('T')[0];
  }

  return {
    visitNumber: visitCount + 1,
    recommendedGestationalAge: nextVisitWeeks,
    recommendedDate: nextVisitDate,
    schedule: nextVisitSchedule,
    requiredAssessments: nextVisitSchedule ? nextVisitSchedule.required_assessments : [],
    priority: nextVisitSchedule ? nextVisitSchedule.priority : 'low'
  };
}

/**
 * Calculate DAK indicators
 * @param {Array} ancVisits - Array of ANC visit data
 * @param {Array} patients - Array of patient data
 * @returns {Object} DAK indicators
 */
function calculateDAKIndicators(ancVisits, patients) {
  const indicators = {};

  // ANC.IND.01: Early ANC Initiation
  const earlyVisits = ancVisits.filter(v => {
    const gestationWeeks = v.gestation_weeks || 0;
    return gestationWeeks < 12 && gestationWeeks > 0;
  });
  indicators['ANC.IND.01'] = {
    name: DAK_INDICATORS['ANC.IND.01'].name,
    value: ancVisits.length > 0 ? (earlyVisits.length / ancVisits.length) * 100 : 0,
    numerator: earlyVisits.length,
    denominator: ancVisits.length,
    target: DAK_INDICATORS['ANC.IND.01'].target,
    status: ancVisits.length > 0 ? (earlyVisits.length / ancVisits.length) * 100 >= DAK_INDICATORS['ANC.IND.01'].target ? 'met' : 'not_met' : 'no_data'
  };

  // ANC.IND.02: Four or More ANC Visits
  const fourPlusVisits = ancVisits.filter(v => v.visit_number >= 4);
  indicators['ANC.IND.02'] = {
    name: DAK_INDICATORS['ANC.IND.02'].name,
    value: ancVisits.length > 0 ? (fourPlusVisits.length / ancVisits.length) * 100 : 0,
    numerator: fourPlusVisits.length,
    denominator: ancVisits.length,
    target: DAK_INDICATORS['ANC.IND.02'].target,
    status: ancVisits.length > 0 ? (fourPlusVisits.length / ancVisits.length) * 100 >= DAK_INDICATORS['ANC.IND.02'].target ? 'met' : 'not_met' : 'no_data'
  };

  // ANC.IND.04: HIV Testing Coverage
  const hivTested = ancVisits.filter(v => v.hiv_test_done === true && v.hiv_test_result && v.hiv_test_result !== 'pending');
  indicators['ANC.IND.04'] = {
    name: DAK_INDICATORS['ANC.IND.04'].name,
    value: ancVisits.length > 0 ? (hivTested.length / ancVisits.length) * 100 : 0,
    numerator: hivTested.length,
    denominator: ancVisits.length,
    target: DAK_INDICATORS['ANC.IND.04'].target,
    status: ancVisits.length > 0 ? (hivTested.length / ancVisits.length) * 100 >= DAK_INDICATORS['ANC.IND.04'].target ? 'met' : 'not_met' : 'no_data'
  };

  // ANC.IND.05: Syphilis Screening Coverage
  const syphilisScreened = ancVisits.filter(v => v.syphilis_test_done === true && v.syphilis_test_result && v.syphilis_test_result !== 'pending');
  indicators['ANC.IND.05'] = {
    name: DAK_INDICATORS['ANC.IND.05'].name,
    value: ancVisits.length > 0 ? (syphilisScreened.length / ancVisits.length) * 100 : 0,
    numerator: syphilisScreened.length,
    denominator: ancVisits.length,
    target: DAK_INDICATORS['ANC.IND.05'].target,
    status: ancVisits.length > 0 ? (syphilisScreened.length / ancVisits.length) * 100 >= DAK_INDICATORS['ANC.IND.05'].target ? 'met' : 'not_met' : 'no_data'
  };

  // ANC.IND.06: Iron Supplementation Coverage
  const ironSupplemented = ancVisits.filter(v => v.iron_supplement_given === true);
  indicators['ANC.IND.06'] = {
    name: DAK_INDICATORS['ANC.IND.06'].name,
    value: ancVisits.length > 0 ? (ironSupplemented.length / ancVisits.length) * 100 : 0,
    numerator: ironSupplemented.length,
    denominator: ancVisits.length,
    target: DAK_INDICATORS['ANC.IND.06'].target,
    status: ancVisits.length > 0 ? (ironSupplemented.length / ancVisits.length) * 100 >= DAK_INDICATORS['ANC.IND.06'].target ? 'met' : 'not_met' : 'no_data'
  };

  // ANC.IND.07: Tetanus Immunization Coverage
  const tetanusImmunized = ancVisits.filter(v => v.tetanus_toxoid_given === true && v.tetanus_toxoid_dose && v.tetanus_toxoid_dose >= 2);
  indicators['ANC.IND.07'] = {
    name: DAK_INDICATORS['ANC.IND.07'].name,
    value: ancVisits.length > 0 ? (tetanusImmunized.length / ancVisits.length) * 100 : 0,
    numerator: tetanusImmunized.length,
    denominator: ancVisits.length,
    target: DAK_INDICATORS['ANC.IND.07'].target,
    status: ancVisits.length > 0 ? (tetanusImmunized.length / ancVisits.length) * 100 >= DAK_INDICATORS['ANC.IND.07'].target ? 'met' : 'not_met' : 'no_data'
  };

  return indicators;
}

module.exports = {
  DAK_DECISION_POINTS,
  DAK_SCHEDULING,
  DAK_INDICATORS,
  generateDAKDecisionSupportAlerts,
  calculateNextDAKVisit,
  calculateDAKIndicators
};
