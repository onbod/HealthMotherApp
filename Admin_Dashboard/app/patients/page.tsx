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

const mapFhirPatientToTable = (patient: any): Patient => ({
  id: patient.id,
  name: patient.name?.[0]?.text || (patient.name?.[0]?.given?.join(' ') + ' ' + patient.name?.[0]?.family) || '',
  age: patient.birthDate ? new Date().getFullYear() - new Date(patient.birthDate).getFullYear() : 0,
  phone: patient.telecom?.find((t: any) => t.system === 'phone')?.value || '',
  email: patient.telecom?.find((t: any) => t.system === 'email')?.value || '',
  address: patient.address?.[0]?.line?.join(', ') || '',
  emergencyContact: patient.contact?.[0]?.name?.text || '',
  riskLevel: 'Low', // You can enhance this logic
  status: 'Active', // You can enhance this logic
  weeks: 0, // You can enhance this logic
  dueDate: '', // You can enhance this logic
});

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
        const res = await fetch(getApiUrl('/fhir/Patient'), {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (!res.ok) throw new Error('Failed to fetch patients');
        const data = await res.json();
        const fhirPatients = data.entry?.map((e: any) => e.resource) || [];
        setPatients(fhirPatients.map(mapFhirPatientToTable));
      } catch (err: any) {
        setError(err.message || 'Error fetching patients');
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const filtered = patients.filter(p => p.name.toLowerCase().includes(search.toLowerCase()));

  // Dashboard stats
  const totalPatients = patients.length;
  const activePatients = patients.filter(p => p.status === "Active").length;
  const deliveredPatients = patients.filter(p => p.status === "Delivered").length;
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
              {filtered.map((patient) => (
                <TableRow key={patient.id} className="hover:bg-gray-50 cursor-pointer">
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