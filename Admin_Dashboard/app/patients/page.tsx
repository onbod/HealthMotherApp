"use client"

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PatientDetail } from "@/components/patient-detail";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { getApiUrl } from "@/lib/config";

// Define a type for Patient
interface Patient {
  id: string;
  name: string;
  age: number;
  phone: string;
  email: string;
  address: string;
  emergencyContact: string;
  riskLevel: string;
  status: string;
  weeks: number;
  dueDate: string;
}

// Patient mapping helper
function mapApiPatientToFrontend(patient: any, index?: number) {
  // Ensure we always have a unique ID
  const uniqueId = patient.patient_id || patient.id || patient.identifier || `patient-${index ?? Date.now()}-${Math.random()}`;
  
  // Build full name from available fields
  let fullName = '';
  if (patient.name) {
    fullName = patient.name;
  } else if (patient.first_name || patient.last_name) {
    fullName = [patient.first_name, patient.middle_name, patient.last_name].filter(Boolean).join(' ');
  } else if (patient.client_number) {
    fullName = patient.client_number;
  }
  
  // Determine status: use patient_status from query, or pregnancy_status, or default to Active
  let status = 'Active';
  if (patient.patient_status) {
    status = patient.patient_status;
  } else if (patient.pregnancy_status === 'completed') {
    status = 'Delivered';
  } else if (patient.pregnancy_status === 'active') {
    status = 'Active';
  }
  
  // Determine risk level: use risk_level from risk assessment, or anc_risk_level, or default to Low
  let riskLevel = 'Low';
  if (patient.risk_level) {
    riskLevel = String(patient.risk_level).charAt(0).toUpperCase() + String(patient.risk_level).slice(1).toLowerCase();
  } else if (patient.anc_risk_level) {
    riskLevel = String(patient.anc_risk_level).charAt(0).toUpperCase() + String(patient.anc_risk_level).slice(1).toLowerCase();
  }
  
  // Format due date
  let dueDate = '';
  if (patient.edd_date) {
    dueDate = new Date(patient.edd_date).toISOString().split('T')[0];
  } else if (patient.due_date) {
    dueDate = patient.due_date;
  }
  
  return {
    id: String(uniqueId), // Ensure ID is always a string
    name: fullName || `Patient ${uniqueId}`,
    age: patient.age || (patient.birth_date ? Math.floor((new Date().getTime() - new Date(patient.birth_date).getTime()) / (365.25 * 24 * 60 * 60 * 1000)) : 0),
    phone: patient.phone || patient.alternative_phone || '',
    email: patient.email || '',
    address: patient.address || '',
    emergencyContact: patient.emergency_contact || '',
    riskLevel: riskLevel,
    status: status,
    // Calculate weeks using the same priority logic as Flutter app
    // Use calculated_weeks from backend (which already applies Flutter app logic)
    weeks: (() => {
      let weeks = 0;
      if (patient.calculated_weeks !== null && patient.calculated_weeks !== undefined && Number(patient.calculated_weeks) > 0) {
        weeks = Number(patient.calculated_weeks);
      } else if (patient.latest_visit_gestation_weeks !== null && patient.latest_visit_gestation_weeks !== undefined && Number(patient.latest_visit_gestation_weeks) > 0) {
        // Fallback: If we have visit date, calculate days since visit
        if (patient.latest_visit_date) {
          const visitDate = new Date(patient.latest_visit_date);
          const daysSinceVisit = Math.floor((new Date().getTime() - visitDate.getTime()) / (1000 * 60 * 60 * 24));
          const daysAtVisit = Number(patient.latest_visit_gestation_weeks) * 7;
          const currentDays = Math.min(280, Math.max(1, daysAtVisit + daysSinceVisit));
          weeks = Math.floor(currentDays / 7);
        } else {
          weeks = Number(patient.latest_visit_gestation_weeks);
        }
      } else if (patient.current_gestation_weeks !== null && patient.current_gestation_weeks !== undefined && Number(patient.current_gestation_weeks) > 0) {
        weeks = Number(patient.current_gestation_weeks);
      } else if (patient.lmp_date) {
        // Calculate from LMP
        const lmpDate = new Date(patient.lmp_date);
        const diffDays = Math.floor((new Date().getTime() - lmpDate.getTime()) / (1000 * 60 * 60 * 24));
        weeks = Math.floor(diffDays / 7);
      }
      return Math.min(40, Math.max(0, weeks));
    })(),
    dueDate: dueDate,
    clientNumber: patient.identifier || patient.client_number,
    birthDate: patient.birth_date,
    pregnancyId: patient.pregnancy_id,
    deliveryCount: patient.delivery_count || 0,
    // Add more fields as needed
  };
}

export default function PatientsPage() {
  const [patients, setPatients] = useState<Patient[]>([]);
  const [search, setSearch] = useState("");
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [showDetail, setShowDetail] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      setError(null);
      try {
        const token = typeof window !== 'undefined' ? localStorage.getItem('adminToken') : '';
        if (!token) throw new Error('No admin token found');
        const res = await fetch(getApiUrl('/api/patient'), {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (!res.ok) throw new Error('Failed to fetch patients');
        const data = await res.json();
        console.log('Patients API response:', data);
        
        // Handle different response formats
        let patients = [];
        if (Array.isArray(data)) {
          // Direct array response
          patients = data.map((p: any, idx: number) => mapApiPatientToFrontend(p, idx));
        } else if (data.data && Array.isArray(data.data)) {
          // Response with { success: true, data: [...] } format
          patients = data.data.map((p: any, idx: number) => mapApiPatientToFrontend(p, idx));
        } else if (data.entry && Array.isArray(data.entry)) {
          // FHIR bundle format
          const fhirPatients = data.entry?.map((e: any) => e.resource) || [];
          patients = fhirPatients.map((p: any, idx: number) => mapApiPatientToFrontend(p, idx));
        } else {
          console.error('Unexpected patient data format:', data);
          patients = [];
        }
        
        // Debug: Log first patient's raw API data and mapped data
        if (patients.length > 0 && Array.isArray(data) && data.length > 0) {
          console.log('First patient RAW API data:', {
            patient_id: data[0].patient_id,
            calculated_weeks: data[0].calculated_weeks,
            latest_visit_date: data[0].latest_visit_date,
            latest_visit_gestation_weeks: data[0].latest_visit_gestation_weeks,
            current_gestation_weeks: data[0].current_gestation_weeks,
            delivery_count: data[0].delivery_count,
            lmp_date: data[0].lmp_date,
            pregnancy_status: data[0].pregnancy_status
          });
          console.log('First patient mapped data:', {
            id: patients[0].id,
            name: patients[0].name,
            weeks: patients[0].weeks,
            deliveryCount: patients[0].deliveryCount,
            status: patients[0].status
          });
        }
        
        setPatients(patients);
      } catch (err: any) {
        setError(err.message || 'Error fetching patients');
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const filtered = patients.filter(p =>
    (p.name || '').toLowerCase().includes(search.toLowerCase())
  );

  // Dashboard stats
  const totalPatients = patients.length;
  const activePatients = patients.filter(p => p.status === "Active").length;
  // Count total deliveries (sum of all delivery_count values)
  const deliveredPatients = patients.reduce((sum, p) => sum + (p.deliveryCount || 0), 0);
  const highRiskPatients = patients.filter(p => p.riskLevel === "High").length;

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold">Patients</h1>
          <p className="text-muted-foreground text-sm sm:text-base">List of patients under your care</p>
        </div>
      </div>
      {/* Dashboard summary */}
      <div className="grid gap-3 sm:gap-4 grid-cols-2 md:grid-cols-4">
        <Card className="bg-gradient-to-br from-yellow-600 to-yellow-700 text-white">
          <CardHeader>
            <CardTitle>Total Patients</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalPatients}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-blue-600 to-blue-700 text-white">
          <CardHeader>
            <CardTitle>Active</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activePatients}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-green-600 to-green-700 text-white">
          <CardHeader>
            <CardTitle>Delivered</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{deliveredPatients}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-red-600 to-red-700 text-white">
          <CardHeader>
            <CardTitle>High Risk</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{highRiskPatients}</div>
          </CardContent>
        </Card>
      </div>
      <Input placeholder="Search patients..." value={search} onChange={e => setSearch(e.target.value)} className="max-w-xs" />
      {/* Loading and error states */}
      {loading && <div>Loading patients...</div>}
      {error && <div className="text-red-600">{error}</div>}
      {/* Table view for patients */}
      {!loading && !error && (
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Age</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Weeks</TableHead>
                <TableHead>Due Date</TableHead>
                <TableHead>Risk</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((patient, index) => (
                <TableRow key={patient.id || `patient-${index}`} className="hover:bg-gray-50 cursor-pointer">
                  <TableCell>{patient.name}</TableCell>
                  <TableCell>{patient.age}</TableCell>
                  <TableCell>
                    <Badge variant={patient.status === "Delivered" ? "secondary" : "default"}>{patient.status}</Badge>
                  </TableCell>
                  <TableCell>{patient.weeks}</TableCell>
                  <TableCell>{patient.dueDate}</TableCell>
                  <TableCell>
                    <Badge variant={patient.riskLevel === "High" ? "destructive" : patient.riskLevel === "Medium" ? "secondary" : "outline"}>{patient.riskLevel}</Badge>
                  </TableCell>
                  <TableCell>
                    <Button size="sm" variant="outline" onClick={() => { setSelectedPatient(patient); setShowDetail(true); }}>View</Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
      {/* Patient Detail Modal */}
      {showDetail && selectedPatient && (
        <div
          className="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
          onClick={e => {
            if (e.target === e.currentTarget) setShowDetail(false);
          }}
        >
          <div className="bg-white rounded-lg p-4 w-full max-w-3xl max-h-[90vh] overflow-y-auto">
            <PatientDetail patient={selectedPatient} onBack={() => setShowDetail(false)} />
          </div>
        </div>
      )}
    </div>
  );
} 