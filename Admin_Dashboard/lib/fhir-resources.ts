// FHIR resource mappers for your app

export function toFhirPatient(patient: any) {
  return {
    resourceType: "Patient",
    id: patient.id,
    identifier: [
      {
        system: "https://yourapp.com/patients",
        value: patient.clientNumber,
      },
    ],
    name: [
      {
        use: "official",
        text: patient.basicInfo?.clientName || "",
      },
    ],
    gender: patient.basicInfo?.gender || "unknown",
    birthDate: patient.basicInfo?.birthDate || "",
    telecom: [
      {
        system: "phone",
        value: patient.basicInfo?.phoneNumber || "",
      },
    ],
    address: [
      {
        text: patient.basicInfo?.address || "",
      },
    ],
    contact: [
      {
        name: {
          text: patient.basicInfo?.emergencyContact || "",
        },
      },
    ],
  };
}

export function toFhirEncounter(patientId: string, visit: any, visitNumber: number) {
  return {
    resourceType: "Encounter",
    id: `${patientId}-visit${visitNumber}`,
    status: "finished",
    class: {
      system: "http://terminology.hl7.org/CodeSystem/v3-ActCode",
      code: "AMB",
      display: "ambulatory",
    },
    subject: {
      reference: `Patient/${patientId}`,
    },
    period: {
      start: visit.presentPregnancy?.dateOfAncContact || "",
    },
    reasonCode: [
      {
        text: "Antenatal care",
      },
    ],
    location: [
      {
        display: visit.facilityInfo?.name || "",
      },
    ],
  };
}

export function toFhirObservation({
  patientId,
  encounterId,
  code,
  value,
  unit,
  effectiveDateTime,
  category = "vital-signs"
}: {
  patientId: string,
  encounterId: string,
  code: { system: string, code: string, display: string },
  value: number | string,
  unit: string,
  effectiveDateTime: string,
  category?: string
}) {
  return {
    resourceType: "Observation",
    status: "final",
    category: [
      {
        coding: [
          {
            system: "http://terminology.hl7.org/CodeSystem/observation-category",
            code: category,
            display: category.replace("-", " ")
          }
        ]
      }
    ],
    code: {
      coding: [code],
      text: code.display
    },
    subject: {
      reference: `Patient/${patientId}`
    },
    encounter: {
      reference: `Encounter/${encounterId}`
    },
    effectiveDateTime,
    valueQuantity: {
      value: value,
      unit: unit
    }
  }
}

// Add similar functions for Observation, Condition, Communication, etc.
