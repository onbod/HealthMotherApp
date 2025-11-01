/**
 * FHIR R4 Compliance Module
 * Implements full HL7 FHIR R4 compliance for the Healthy Mother App
 */

const fhirVersion = '4.0.1';
const fhirRelease = 'R4';

// FHIR R4 CapabilityStatement
const getCapabilityStatement = () => {
  return {
    resourceType: 'CapabilityStatement',
    id: 'health-fhir-backend',
    url: 'https://health-fhir-backend-production-6ae1.up.railway.app/metadata',
    version: '1.0.0',
    name: 'Healthy Mother FHIR Server',
    title: 'Healthy Mother Maternal Health FHIR Server',
    status: 'active',
    experimental: false,
    date: new Date().toISOString(),
    publisher: 'Healthy Mother App',
    description: 'FHIR R4 compliant server for maternal and child health applications with DAK integration',
    purpose: 'Provide FHIR R4 compliant API for maternal health data management with WHO DAK standards',
    fhirVersion: fhirVersion,
    format: ['application/fhir+json', 'application/fhir+xml'],
    patchFormat: ['application/json-patch+json'],
    implementation: {
      description: 'Healthy Mother FHIR Server Implementation',
      url: 'https://health-fhir-backend-production-6ae1.up.railway.app'
    },
    software: {
      name: 'Healthy Mother FHIR Server',
      version: '1.0.0',
      releaseDate: new Date().toISOString()
    },
    rest: [
      {
        mode: 'server',
        documentation: 'FHIR R4 compliant REST API for maternal health',
        security: {
          cors: true,
          service: [
            {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/restful-security-service',
                  code: 'OAuth',
                  display: 'OAuth 2.0'
                }
              ]
            }
          ]
        },
        resource: [
          // Patient Resource
          {
            type: 'Patient',
            profile: 'http://hl7.org/fhir/StructureDefinition/Patient',
            documentation: 'Patient demographics and contact information',
            interaction: [
              { code: 'read' },
              { code: 'vread' },
              { code: 'update' },
              { code: 'patch' },
              { code: 'delete' },
              { code: 'history-instance' },
              { code: 'create' },
              { code: 'search-type' }
            ],
            versioning: 'versioned-update',
            conditionalCreate: true,
            conditionalRead: 'not-supported',
            conditionalUpdate: true,
            conditionalDelete: 'not-supported',
            searchInclude: ['Patient:general-practitioner', 'Patient:link'],
            searchRevInclude: ['Encounter:patient', 'Observation:patient', 'Condition:patient'],
            searchParam: [
              {
                name: 'identifier',
                type: 'token',
                documentation: 'A patient identifier',
                definition: 'http://hl7.org/fhir/SearchParameter/Patient-identifier'
              },
              {
                name: 'name',
                type: 'string',
                documentation: 'A portion of either family or given name of the patient',
                definition: 'http://hl7.org/fhir/SearchParameter/Patient-name'
              },
              {
                name: 'telecom',
                type: 'token',
                documentation: 'The value in any kind of telecom details of the patient',
                definition: 'http://hl7.org/fhir/SearchParameter/Patient-telecom'
              },
              {
                name: 'gender',
                type: 'token',
                documentation: 'Administrative gender - the gender that the patient is considered to have for administration and record keeping purposes',
                definition: 'http://hl7.org/fhir/SearchParameter/Patient-gender'
              },
              {
                name: 'birthdate',
                type: 'date',
                documentation: 'The patient\'s date of birth',
                definition: 'http://hl7.org/fhir/SearchParameter/Patient-birthdate'
              },
              {
                name: 'address',
                type: 'string',
                documentation: 'A server defined search that may match any of the string fields in the Address, including line, city, district, state, country, postalCode, and/or text',
                definition: 'http://hl7.org/fhir/SearchParameter/Patient-address'
              }
            ]
          },
          // Observation Resource
          {
            type: 'Observation',
            profile: 'http://hl7.org/fhir/StructureDefinition/Observation',
            documentation: 'Measurements and simple assertions made about a patient',
            interaction: [
              { code: 'read' },
              { code: 'vread' },
              { code: 'update' },
              { code: 'patch' },
              { code: 'delete' },
              { code: 'history-instance' },
              { code: 'create' },
              { code: 'search-type' }
            ],
            versioning: 'versioned-update',
            conditionalCreate: true,
            conditionalRead: 'not-supported',
            conditionalUpdate: true,
            conditionalDelete: 'not-supported',
            searchInclude: ['Observation:patient', 'Observation:encounter', 'Observation:performer'],
            searchRevInclude: [],
            searchParam: [
              {
                name: 'patient',
                type: 'reference',
                documentation: 'The subject that the observation is about',
                definition: 'http://hl7.org/fhir/SearchParameter/Observation-patient'
              },
              {
                name: 'category',
                type: 'token',
                documentation: 'The classification of the type of observation',
                definition: 'http://hl7.org/fhir/SearchParameter/Observation-category'
              },
              {
                name: 'code',
                type: 'token',
                documentation: 'The code of the observation type',
                definition: 'http://hl7.org/fhir/SearchParameter/Observation-code'
              },
              {
                name: 'date',
                type: 'date',
                documentation: 'Obtained date/time',
                definition: 'http://hl7.org/fhir/SearchParameter/Observation-date'
              },
              {
                name: 'status',
                type: 'token',
                documentation: 'The status of the observation',
                definition: 'http://hl7.org/fhir/SearchParameter/Observation-status'
              }
            ]
          },
          // Encounter Resource
          {
            type: 'Encounter',
            profile: 'http://hl7.org/fhir/StructureDefinition/Encounter',
            documentation: 'An interaction between a patient and healthcare provider(s)',
            interaction: [
              { code: 'read' },
              { code: 'vread' },
              { code: 'update' },
              { code: 'patch' },
              { code: 'delete' },
              { code: 'history-instance' },
              { code: 'create' },
              { code: 'search-type' }
            ],
            versioning: 'versioned-update',
            conditionalCreate: true,
            conditionalRead: 'not-supported',
            conditionalUpdate: true,
            conditionalDelete: 'not-supported',
            searchInclude: ['Encounter:patient', 'Encounter:practitioner', 'Encounter:location'],
            searchRevInclude: ['Observation:encounter', 'Condition:encounter'],
            searchParam: [
              {
                name: 'patient',
                type: 'reference',
                documentation: 'The patient present at the encounter',
                definition: 'http://hl7.org/fhir/SearchParameter/Encounter-patient'
              },
              {
                name: 'status',
                type: 'token',
                documentation: 'planned | arrived | triaged | in-progress | onleave | finished | cancelled +',
                definition: 'http://hl7.org/fhir/SearchParameter/Encounter-status'
              },
              {
                name: 'class',
                type: 'token',
                documentation: 'Classification of patient encounter',
                definition: 'http://hl7.org/fhir/SearchParameter/Encounter-class'
              },
              {
                name: 'date',
                type: 'date',
                documentation: 'A date within the period the Encounter lasted',
                definition: 'http://hl7.org/fhir/SearchParameter/Encounter-date'
              }
            ]
          },
          // Condition Resource
          {
            type: 'Condition',
            profile: 'http://hl7.org/fhir/StructureDefinition/Condition',
            documentation: 'Detailed information about conditions, problems or diagnoses',
            interaction: [
              { code: 'read' },
              { code: 'vread' },
              { code: 'update' },
              { code: 'patch' },
              { code: 'delete' },
              { code: 'history-instance' },
              { code: 'create' },
              { code: 'search-type' }
            ],
            versioning: 'versioned-update',
            conditionalCreate: true,
            conditionalRead: 'not-supported',
            conditionalUpdate: true,
            conditionalDelete: 'not-supported',
            searchInclude: ['Condition:patient', 'Condition:encounter'],
            searchRevInclude: [],
            searchParam: [
              {
                name: 'patient',
                type: 'reference',
                documentation: 'Who has the condition?',
                definition: 'http://hl7.org/fhir/SearchParameter/Condition-patient'
              },
              {
                name: 'category',
                type: 'token',
                documentation: 'The category of the condition',
                definition: 'http://hl7.org/fhir/SearchParameter/Condition-category'
              },
              {
                name: 'clinical-status',
                type: 'token',
                documentation: 'The clinical status of the condition',
                definition: 'http://hl7.org/fhir/SearchParameter/Condition-clinical-status'
              },
              {
                name: 'verification-status',
                type: 'token',
                documentation: 'The verification status of the condition',
                definition: 'http://hl7.org/fhir/SearchParameter/Condition-verification-status'
              }
            ]
          },
          // Communication Resource
          {
            type: 'Communication',
            profile: 'http://hl7.org/fhir/StructureDefinition/Communication',
            documentation: 'An occurrence of information being transmitted',
            interaction: [
              { code: 'read' },
              { code: 'vread' },
              { code: 'update' },
              { code: 'patch' },
              { code: 'delete' },
              { code: 'history-instance' },
              { code: 'create' },
              { code: 'search-type' }
            ],
            versioning: 'versioned-update',
            conditionalCreate: true,
            conditionalRead: 'not-supported',
            conditionalUpdate: true,
            conditionalDelete: 'not-supported',
            searchInclude: ['Communication:sender', 'Communication:recipient', 'Communication:subject'],
            searchRevInclude: [],
            searchParam: [
              {
                name: 'patient',
                type: 'reference',
                documentation: 'The patient who is the subject of the communication',
                definition: 'http://hl7.org/fhir/SearchParameter/Communication-patient'
              },
              {
                name: 'sender',
                type: 'reference',
                documentation: 'Message sender',
                definition: 'http://hl7.org/fhir/SearchParameter/Communication-sender'
              },
              {
                name: 'recipient',
                type: 'reference',
                documentation: 'Message recipient',
                definition: 'http://hl7.org/fhir/SearchParameter/Communication-recipient'
              },
              {
                name: 'status',
                type: 'token',
                documentation: 'preparation | in-progress | not-done | on-hold | stopped | completed | entered-in-error | unknown',
                definition: 'http://hl7.org/fhir/SearchParameter/Communication-status'
              },
              {
                name: 'sent',
                type: 'date',
                documentation: 'When sent',
                definition: 'http://hl7.org/fhir/SearchParameter/Communication-sent'
              }
            ]
          }
        ],
        operation: [
          {
            name: 'validate',
            definition: {
              reference: 'http://hl7.org/fhir/OperationDefinition/Resource-validate'
            },
            documentation: 'Validate a resource'
          },
          {
            name: 'everything',
            definition: {
              reference: 'http://hl7.org/fhir/OperationDefinition/Patient-everything'
            },
            documentation: 'Get everything for a patient'
          }
        ]
      }
    ],
    messaging: [
      {
        endpoint: [
          {
            protocol: {
              system: 'http://hl7.org/fhir/message-transport',
              code: 'http'
            },
            address: 'https://health-fhir-backend-production-6ae1.up.railway.app/messaging'
          }
        ],
        reliableCache: 30,
        documentation: 'Messaging endpoint for FHIR operations'
      }
    ]
  };
};

// FHIR R4 Search Parameters
const getSearchParameters = () => {
  return {
    resourceType: 'SearchParameter',
    id: 'search-parameters',
    url: 'https://health-fhir-backend-production-6ae1.up.railway.app/SearchParameter',
    version: '1.0.0',
    name: 'Healthy Mother Search Parameters',
    status: 'active',
    experimental: false,
    date: new Date().toISOString(),
    publisher: 'Healthy Mother App',
    description: 'Search parameters for maternal health resources',
    code: 'search-parameters',
    base: ['Patient', 'Observation', 'Encounter', 'Condition', 'Communication'],
    type: 'string',
    expression: 'Resource',
    xpath: 'f:Resource',
    target: ['Patient', 'Observation', 'Encounter', 'Condition', 'Communication']
  };
};

// FHIR R4 Operation Definitions
const getOperationDefinitions = () => {
  return [
    {
      resourceType: 'OperationDefinition',
      id: 'validate-resource',
      url: 'https://health-fhir-backend-production-6ae1.up.railway.app/OperationDefinition/validate-resource',
      version: '1.0.0',
      name: 'Validate Resource',
      status: 'active',
      kind: 'operation',
      code: 'validate',
      system: false,
      type: true,
      instance: false,
      parameter: [
        {
          name: 'resource',
          use: 'in',
          min: 1,
          max: '1',
          type: 'Resource',
          documentation: 'The resource to validate'
        },
        {
          name: 'profile',
          use: 'in',
          min: 0,
          max: '1',
          type: 'uri',
          documentation: 'The profile to validate against'
        },
        {
          name: 'return',
          use: 'out',
          min: 1,
          max: '1',
          type: 'OperationOutcome',
          documentation: 'The validation results'
        }
      ]
    },
    {
      resourceType: 'OperationDefinition',
      id: 'patient-everything',
      url: 'https://health-fhir-backend-production-6ae1.up.railway.app/OperationDefinition/patient-everything',
      version: '1.0.0',
      name: 'Patient Everything',
      status: 'active',
      kind: 'operation',
      code: 'everything',
      system: false,
      type: false,
      instance: true,
      parameter: [
        {
          name: 'start',
          use: 'in',
          min: 0,
          max: '1',
          type: 'date',
          documentation: 'The start date for the everything operation'
        },
        {
          name: 'end',
          use: 'in',
          min: 0,
          max: '1',
          type: 'date',
          documentation: 'The end date for the everything operation'
        },
        {
          name: 'return',
          use: 'out',
          min: 1,
          max: '1',
          type: 'Bundle',
          documentation: 'A Bundle containing all resources for the patient'
        }
      ]
    }
  ];
};

// FHIR R4 Structure Definitions
const getStructureDefinitions = () => {
  return [
    {
      resourceType: 'StructureDefinition',
      id: 'maternal-health-patient',
      url: 'https://health-fhir-backend-production-6ae1.up.railway.app/StructureDefinition/maternal-health-patient',
      version: '1.0.0',
      name: 'Maternal Health Patient',
      title: 'Maternal Health Patient Profile',
      status: 'active',
      experimental: false,
      date: new Date().toISOString(),
      publisher: 'Healthy Mother App',
      description: 'A profile for maternal health patients with additional fields for pregnancy tracking',
      fhirVersion: fhirVersion,
      kind: 'resource',
      abstract: false,
      type: 'Patient',
      baseDefinition: 'http://hl7.org/fhir/StructureDefinition/Patient',
      derivation: 'constraint',
      differential: {
        element: [
          {
            id: 'Patient',
            path: 'Patient',
            short: 'Maternal Health Patient',
            definition: 'A patient profile for maternal health applications'
          },
          {
            id: 'Patient.extension',
            path: 'Patient.extension',
            short: 'Additional maternal health extensions'
          },
          {
            id: 'Patient.extension:pregnancy-status',
            path: 'Patient.extension',
            sliceName: 'pregnancy-status',
            short: 'Current pregnancy status',
            definition: 'The current pregnancy status of the patient',
            type: [
              {
                code: 'Extension',
                profile: 'http://hl7.org/fhir/StructureDefinition/Extension'
              }
            ]
          }
        ]
      }
    }
  ];
};

// FHIR R4 Value Sets
const getValueSets = () => {
  return [
    {
      resourceType: 'ValueSet',
      id: 'maternal-health-categories',
      url: 'https://health-fhir-backend-production-6ae1.up.railway.app/ValueSet/maternal-health-categories',
      version: '1.0.0',
      name: 'Maternal Health Categories',
      title: 'Maternal Health Observation Categories',
      status: 'active',
      experimental: false,
      date: new Date().toISOString(),
      publisher: 'Healthy Mother App',
      description: 'Categories for maternal health observations',
      compose: {
        include: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/observation-category',
            concept: [
              {
                code: 'vital-signs',
                display: 'Vital Signs'
              },
              {
                code: 'laboratory',
                display: 'Laboratory'
              },
              {
                code: 'exam',
                display: 'Examination'
              }
            ]
          }
        ]
      }
    }
  ];
};

// FHIR R4 Validation Functions
const validateFhirResource = (resource) => {
  const errors = [];
  
  // Basic validation
  if (!resource.resourceType) {
    errors.push('Resource must have a resourceType');
  }
  
  if (!resource.id && !resource.identifier) {
    errors.push('Resource must have either an id or identifier');
  }
  
  // Resource-specific validation
  switch (resource.resourceType) {
    case 'Patient':
      if (!resource.name || resource.name.length === 0) {
        errors.push('Patient must have at least one name');
      }
      break;
    case 'Observation':
      if (!resource.status) {
        errors.push('Observation must have a status');
      }
      if (!resource.code) {
        errors.push('Observation must have a code');
      }
      break;
    case 'Encounter':
      if (!resource.status) {
        errors.push('Encounter must have a status');
      }
      if (!resource.class) {
        errors.push('Encounter must have a class');
      }
      break;
  }
  
  return {
    valid: errors.length === 0,
    errors: errors
  };
};

// FHIR R4 Search Functions
const buildSearchQuery = (resourceType, searchParams) => {
  let query = `SELECT * FROM ${resourceType.toLowerCase()}`;
  const conditions = [];
  const values = [];
  let paramCount = 1;
  
  for (const [param, value] of Object.entries(searchParams)) {
    switch (param) {
      case 'identifier':
        conditions.push(`identifier = $${paramCount}`);
        values.push(value);
        paramCount++;
        break;
      case 'name':
        conditions.push(`name ILIKE $${paramCount}`);
        values.push(`%${value}%`);
        paramCount++;
        break;
      case 'telecom':
        conditions.push(`phone ILIKE $${paramCount}`);
        values.push(`%${value}%`);
        paramCount++;
        break;
      case 'gender':
        conditions.push(`gender = $${paramCount}`);
        values.push(value);
        paramCount++;
        break;
      case 'birthdate':
        conditions.push(`birth_date = $${paramCount}`);
        values.push(value);
        paramCount++;
        break;
      case 'patient':
        conditions.push(`patient_id = $${paramCount}`);
        values.push(value.replace('Patient/', ''));
        paramCount++;
        break;
      case 'status':
        conditions.push(`status = $${paramCount}`);
        values.push(value);
        paramCount++;
        break;
      case 'date':
        conditions.push(`created_at >= $${paramCount}`);
        values.push(value);
        paramCount++;
        break;
    }
  }
  
  if (conditions.length > 0) {
    query += ' WHERE ' + conditions.join(' AND ');
  }
  
  return { query, values };
};

module.exports = {
  getCapabilityStatement,
  getSearchParameters,
  getOperationDefinitions,
  getStructureDefinitions,
  getValueSets,
  validateFhirResource,
  buildSearchQuery,
  fhirVersion,
  fhirRelease
};
