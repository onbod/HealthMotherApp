"use client";

import { PatientDetail } from '@/components/patient-detail';
import { getApiUrl } from '@/lib/config';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import React from 'react';
import { PatientVisitsTabs } from '@/components/patient-profiles';

export default function PatientFullPage({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  const [patient, setPatient] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Unwrap params using React.use()
  const { id } = React.use(params);

  useEffect(() => {
    async function fetchPatient() {
      setLoading(true);
      setError(null);
      try {
        const token = typeof window !== 'undefined' ? localStorage.getItem('adminToken') : '';
        if (!token) throw new Error('No admin token found');
        const res = await fetch(getApiUrl(`/api/patient/${id}`), {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (!res.ok) throw new Error('Failed to fetch patient');
        const data = await res.json();
        console.log('Patient API response:', data);
        
        // Map the patient data to the correct format
        setPatient({
          id: data.id, // numeric id for visit matching
          name: data.name?.[0]?.text || data.client_number || '',
          age: data.age || (data.birth_date ? new Date().getFullYear() - new Date(data.birth_date).getFullYear() : 0),
          phone: data.phone,
          email: data.email || '',
          address: data.address?.text || (Array.isArray(data.address?.line) ? data.address.line.join(', ') : ''),
          emergencyContact: data.emergency_contact?.name || data.emergency_contact?.phone || '',
          riskLevel: data.risk_level || 'Low',
          status: data.status || 'Active',
          weeks: data.weeks || 0,
          dueDate: data.due_date || '',
          clientNumber: data.client_number,
          birthDate: data.birth_date,
        });
      } catch (err: any) {
        setError(err.message || 'Error fetching patient');
      } finally {
        setLoading(false);
      }
    }
    fetchPatient();
  }, [id]);

  if (loading) return <div className="p-8 text-center text-lg">Loading patient details...</div>;
  if (error) return <div className="p-8 text-center text-red-600">{error}</div>;
  if (!patient) return <div className="p-8 text-center">Patient not found.</div>;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="p-4">
        <button
          className="mb-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          onClick={() => router.push('/patients')}
        >
          &larr; Back to Patients
        </button>
        <PatientDetail patient={patient} onBack={() => router.push('/patients')} />
        {/* Show all patient visit data below the profile */}
        <div className="mt-8">
          <PatientVisitsTabs patientId={Number(patient.id)} />
        </div>
      </div>
    </div>
  );
} 