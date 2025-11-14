"use client"

import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PatientDetail } from "@/components/patient-detail";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";

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

const dummyPatients: Patient[] = [
  {
    id: "1",
    name: "Marie Kamara",
    age: 32,
    phone: "1234567890",
    email: "marie.kamara@example.com",
    address: "123 Main St",
    emergencyContact: "Jane Doe",
    riskLevel: "Medium",
    status: "Active",
    weeks: 36,
    dueDate: "2024-02-15",
  },
  {
    id: "2",
    name: "Emmanuella Turay",
    age: 29,
    phone: "2345678901",
    email: "emmanuella.turay@example.com",
    address: "456 Elm St",
    emergencyContact: "John Doe",
    riskLevel: "Low",
    status: "Active",
    weeks: 24,
    dueDate: "2024-03-20",
  },
  {
    id: "3",
    name: "Sarah Conteh",
    age: 24,
    phone: "3456789012",
    email: "sarah.conteh@example.com",
    address: "789 Oak St",
    emergencyContact: "Mary Smith",
    riskLevel: "Low",
    status: "Delivered",
    weeks: 0,
    dueDate: "2024-04-10",
  },
];

export default function PatientsPage() {
  const [patients, setPatients] = useState<Patient[]>(dummyPatients);
  const [search, setSearch] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [showDetail, setShowDetail] = useState(false);
  const [newPatient, setNewPatient] = useState({
    name: "",
    age: "",
    phone: "",
    email: "",
    address: "",
    emergencyContact: "",
    riskLevel: "Low",
    status: "Active",
    weeks: "",
    dueDate: "",
  });

  const filtered = patients.filter(p => p.name.toLowerCase().includes(search.toLowerCase()));

  // Dashboard stats
  const totalPatients = patients.length;
  const activePatients = patients.filter(p => p.status === "Active").length;
  const deliveredPatients = patients.filter(p => p.status === "Delivered").length;
  const highRiskPatients = patients.filter(p => p.riskLevel === "High").length;

  function handleAddPatient(e: React.FormEvent) {
    e.preventDefault();
    setPatients([
      ...patients,
      { ...newPatient, id: (patients.length + 1).toString(), age: Number(newPatient.age), weeks: Number(newPatient.weeks) } as Patient,
    ]);
    setShowAdd(false);
    setNewPatient({ name: "", age: "", phone: "", email: "", address: "", emergencyContact: "", riskLevel: "Low", status: "Active", weeks: "", dueDate: "" });
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold">Patients</h1>
          <p className="text-muted-foreground text-xs sm:text-sm lg:text-base">List of patients under your care</p>
        </div>
        <Button onClick={() => setShowAdd(true)} className="w-full sm:w-auto shrink-0">Add Patient</Button>
      </div>
      {/* Dashboard summary */}
      <div className="grid gap-3 sm:gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-gradient-to-br from-green-600 to-green-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">Total Patients</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{totalPatients}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-blue-600 to-blue-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">Active</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{activePatients}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-red-600 to-red-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">Delivered</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{deliveredPatients}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-yellow-600 to-yellow-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">High Risk</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{highRiskPatients}</div>
          </CardContent>
        </Card>
      </div>
      <Input 
        placeholder="Search patients..." 
        value={search} 
        onChange={e => setSearch(e.target.value)} 
        className="w-full sm:max-w-xs" 
      />
      {/* Table view for patients - Responsive */}
      <div className="overflow-x-auto -mx-4 sm:mx-0">
        <div className="inline-block min-w-full align-middle px-4 sm:px-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs sm:text-sm">Name</TableHead>
                <TableHead className="text-xs sm:text-sm hidden sm:table-cell">Age</TableHead>
                <TableHead className="text-xs sm:text-sm">Status</TableHead>
                <TableHead className="text-xs sm:text-sm hidden md:table-cell">Weeks</TableHead>
                <TableHead className="text-xs sm:text-sm hidden lg:table-cell">Due Date</TableHead>
                <TableHead className="text-xs sm:text-sm">Risk</TableHead>
                <TableHead className="text-xs sm:text-sm">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((patient) => (
                <TableRow key={patient.id} className="hover:bg-gray-50 cursor-pointer">
                  <TableCell className="font-medium text-sm sm:text-base">{patient.name}</TableCell>
                  <TableCell className="text-xs sm:text-sm hidden sm:table-cell">{patient.age}</TableCell>
                  <TableCell>
                    <Badge variant={patient.status === "Delivered" ? "secondary" : "default"} className="text-[10px] sm:text-xs">
                      {patient.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs sm:text-sm hidden md:table-cell">{patient.weeks}</TableCell>
                  <TableCell className="text-xs sm:text-sm hidden lg:table-cell">{patient.dueDate}</TableCell>
                  <TableCell>
                    <Badge 
                      variant={patient.riskLevel === "High" ? "destructive" : patient.riskLevel === "Medium" ? "secondary" : "outline"}
                      className="text-[10px] sm:text-xs"
                    >
                      {patient.riskLevel}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Button 
                      size="sm" 
                      variant="outline" 
                      onClick={() => { setSelectedPatient(patient); setShowDetail(true); }}
                      className="text-xs sm:text-sm px-2 sm:px-3"
                    >
                      View
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </div>
      {/* Add Patient Modal */}
      {showAdd && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h2 className="text-xl font-bold mb-4">Add Patient</h2>
            <form className="space-y-3" onSubmit={handleAddPatient}>
              <input className="w-full border rounded px-2 py-1" placeholder="Name" value={newPatient.name} onChange={e => setNewPatient(p => ({ ...p, name: e.target.value }))} required />
              <input className="w-full border rounded px-2 py-1" placeholder="Age" type="number" value={newPatient.age} onChange={e => setNewPatient(p => ({ ...p, age: e.target.value }))} required />
              <input className="w-full border rounded px-2 py-1" placeholder="Phone" value={newPatient.phone} onChange={e => setNewPatient(p => ({ ...p, phone: e.target.value }))} />
              <input className="w-full border rounded px-2 py-1" placeholder="Email" value={newPatient.email} onChange={e => setNewPatient(p => ({ ...p, email: e.target.value }))} />
              <input className="w-full border rounded px-2 py-1" placeholder="Address" value={newPatient.address} onChange={e => setNewPatient(p => ({ ...p, address: e.target.value }))} />
              <input className="w-full border rounded px-2 py-1" placeholder="Emergency Contact" value={newPatient.emergencyContact} onChange={e => setNewPatient(p => ({ ...p, emergencyContact: e.target.value }))} />
              <input className="w-full border rounded px-2 py-1" placeholder="Weeks" type="number" value={newPatient.weeks} onChange={e => setNewPatient(p => ({ ...p, weeks: e.target.value }))} />
              <input className="w-full border rounded px-2 py-1" placeholder="Due Date" type="date" value={newPatient.dueDate} onChange={e => setNewPatient(p => ({ ...p, dueDate: e.target.value }))} />
              <div className="flex justify-end gap-2 mt-2">
                <Button type="button" variant="outline" onClick={() => setShowAdd(false)}>Cancel</Button>
                <Button type="submit">Add</Button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Patient Detail Modal */}
      {showDetail && selectedPatient && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-3xl max-h-[90vh] overflow-y-auto">
            <PatientDetail patient={selectedPatient} onBack={() => setShowDetail(false)} />
          </div>
        </div>
      )}
    </div>
  );
} 