// Shared Patient model for the app
// Combines FHIR Patient fields and app-specific fields

export interface Patient {
  id: string;
  name: string; // Full name (from FHIR or constructed)
  birthDate?: string; // FHIR birthDate (YYYY-MM-DD)
  age?: number; // Calculated from birthDate
  phone?: string;
  email?: string;
  address?: string;
  emergencyContact?: string;
  riskLevel?: 'Low' | 'Medium' | 'High';
  status?: 'Active' | 'Delivered' | 'Postpartum';
  weeks?: number; // Gestational age in weeks
  dueDate?: string; // Due date (YYYY-MM-DD)
  visits?: any[]; // ANC visits or similar
  // Add more fields as needed
}

// Validate a Patient object (basic example)
export function validatePatient(patient: Partial<Patient>): string[] {
  const errors: string[] = [];
  if (!patient.id) errors.push('Missing id');
  if (!patient.name) errors.push('Missing name');
  // Add more validation as needed
  return errors;
}

// Map FHIR Patient resource to Patient model
export function mapFhirPatientToPatient(fhir: any): Patient {
  const name = fhir.name?.[0]?.text ||
    ((fhir.name?.[0]?.given?.join(' ') + ' ' + fhir.name?.[0]?.family) || '');
  const birthDate = fhir.birthDate;
  const age = birthDate ? new Date().getFullYear() - new Date(birthDate).getFullYear() : undefined;
  const phone = fhir.telecom?.find((t: any) => t.system === 'phone')?.value;
  const email = fhir.telecom?.find((t: any) => t.system === 'email')?.value;
  const address = fhir.address?.[0]?.line?.join(', ');
  // Emergency contact is not standard in FHIR Patient, but may be in extensions or contact
  const emergencyContact = fhir.contact?.[0]?.name?.text;
  // App-specific fields (riskLevel, status, weeks, dueDate, visits) can be set elsewhere
  return {
    id: fhir.id,
    name,
    birthDate,
    age,
    phone,
    email,
    address,
    emergencyContact,
    // riskLevel, status, weeks, dueDate, visits: set in app logic
  };
}

// Optionally: Map Patient model back to FHIR Patient resource
export function mapPatientToFhirPatient(patient: Patient): any {
  return {
    resourceType: 'Patient',
    id: patient.id,
    name: [
      {
        text: patient.name,
        // Optionally split into given/family
      }
    ],
    birthDate: patient.birthDate,
    telecom: [
      ...(patient.phone ? [{ system: 'phone', value: patient.phone }] : []),
      ...(patient.email ? [{ system: 'email', value: patient.email }] : []),
    ],
    address: patient.address ? [{ line: [patient.address] }] : undefined,
    contact: patient.emergencyContact ? [{ name: { text: patient.emergencyContact } }] : undefined,
    // Add more FHIR fields as needed
  };
} 