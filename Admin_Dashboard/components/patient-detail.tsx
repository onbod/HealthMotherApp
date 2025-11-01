"use client"

import { useState, useEffect } from "react"
import { ArrowLeft, Phone, Mail, Calendar, Pill, FileText, Heart, X, AlertTriangle } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Separator } from "@/components/ui/separator"
import { toFhirPatient, toFhirEncounter, toFhirObservation } from "../lib/fhir-resources";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Patient } from "@/lib/patient";
import { PatientVisitsTabs } from './patient-profiles';

interface PatientDetailProps {
  patient: Patient;
  onBack: () => void;
}

// Move these to the top, before PatientDetail is defined
const contactTrimesterMap: Record<number, string> = {
  1: "1st trimester",
  2: "2nd trimester",
  3: "2nd trimester",
  4: "2nd trimester",
  5: "3rd trimester",
  6: "3rd trimester",
  7: "3rd trimester",
  8: "3rd trimester",
};

function getTrimesterForContact(contactNum: number) {
  return contactTrimesterMap[contactNum] || "-";
}


const defaultPatient = {
  visit1: {
    basicInfo: {
      clientName: "Jane Doe",
      age: 28,
      phoneNumber: "123-456-7890",
      email: "jane.doe@example.com",
      address: "123 Main St",
      emergencyContact: "John Doe"
    },
    presentPregnancy: {
      gestationalAge: 12,
      dateOfAncContact: { seconds: Math.floor(Date.now() / 1000) },
      bloodGroup: "O",
      rhesusFactor: "+",
      height: 165,
      weight: 65
    },
    vitals: {
      bloodPressure: "120/80",
      weight: 65,
      height: 165,
      bmi: 24
    },
    pastPregnancyHistory: {
      complications: ["None"]
    }
  },
  visitdelivery: {},
};

export function PatientDetail({ patient, onBack }: PatientDetailProps) {
  if (!patient) {
    return <div>Patient not found</div>;
  }
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-purple-100 rounded-xl shadow-2xl">
      {/* Gradient Header with Avatar */}
      <div className="bg-gradient-to-r from-blue-600 via-purple-500 to-pink-400 px-8 py-6 rounded-t-xl flex items-center justify-between relative">
        <div className="flex items-center gap-5">
          <Button variant="secondary" size="icon" onClick={onBack} className="bg-white/30 hover:bg-white/50 text-white border-none shadow-none">
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <Avatar className="h-16 w-16 ring-4 ring-white/40">
            <AvatarImage src={undefined} alt={patient.name} />
            <AvatarFallback className="bg-white/30 text-2xl font-bold text-white">{patient.name?.[0]}</AvatarFallback>
          </Avatar>
          <div>
            <h1 className="text-3xl font-extrabold text-white drop-shadow-lg">{patient.name}</h1>
            <p className="text-white/80 text-base font-medium">Patient Medical Record</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <Badge variant={patient.status === "Delivered" ? "secondary" : patient.status === "Active" ? "default" : "secondary"} className="text-sm bg-white/30 text-white border-none shadow-none">
            {patient.status || "-"}
          </Badge>
          <Badge variant={patient.riskLevel === 'High' ? 'destructive' : patient.riskLevel === 'Medium' ? 'default' : 'secondary'} className={`text-sm ${patient.riskLevel === 'High' ? 'bg-red-600/80' : patient.riskLevel === 'Medium' ? 'bg-yellow-400/80 text-black' : 'bg-green-500/80'} text-white border-none shadow-none`}>
            {patient.riskLevel || "-"} Risk
          </Badge>
          <Button variant="ghost" size="icon" onClick={onBack} className="absolute top-4 right-4 text-white hover:bg-white/20">
            <X className="h-6 w-6" />
          </Button>
        </div>
      </div>
      {/* Main Content */}
      <div className="flex flex-col md:flex-row gap-8 p-8">
        {/* Left Sidebar - Demographics & Contact */}
        <div className="w-full md:w-1/3 space-y-6">
          <Card className="bg-white/90 shadow-md rounded-lg border-0">
            <CardHeader>
              <CardTitle className="text-blue-700 flex items-center gap-2"><FileText className="w-5 h-5 text-blue-400" /> Demographics</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-gray-700">
                <div><b>Patient ID:</b> {patient.id}</div>
                <div><b>Age:</b> {patient.age ?? "-"}</div>
                <div><b>Date of Birth:</b> {patient.birthDate ?? "-"}</div>
              </div>
            </CardContent>
          </Card>
          <Card className="bg-white/90 shadow-md rounded-lg border-0">
            <CardHeader>
              <CardTitle className="text-purple-700 flex items-center gap-2"><Phone className="w-5 h-5 text-purple-400" /> Contact Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-gray-700">
                <div><Phone className="inline w-4 h-4 mr-1 text-blue-500" /> {patient.phone ?? "-"}</div>
                <div><Mail className="inline w-4 h-4 mr-1 text-pink-500" /> {patient.email ?? "-"}</div>
                <div><b>Address:</b> {patient.address ?? "-"}</div>
                <div><b>Emergency Contact:</b> {patient.emergencyContact ?? "-"}</div>
              </div>
            </CardContent>
          </Card>
        </div>
        {/* Right Content - Pregnancy & Visits */}
        <div className="w-full md:w-2/3 space-y-6">
          <Card className="bg-gradient-to-br from-pink-50 to-purple-100 shadow-md rounded-lg border-0">
            <CardHeader>
              <CardTitle className="text-pink-700 flex items-center gap-2"><Heart className="w-5 h-5 text-pink-400" /> Pregnancy Status</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4 text-gray-700">
                <div><b>Weeks:</b> {patient.weeks ?? "-"}</div>
                <div><b>Trimester:</b> {patient.weeks !== undefined ? (patient.weeks <= 12 ? "1st trimester" : patient.weeks <= 27 ? "2nd trimester" : "3rd trimester") : "-"}</div>
                <div><b>Due Date:</b> {patient.dueDate ?? "-"}</div>
              </div>
            </CardContent>
          </Card>
          {/* Insert PatientVisitsTabs here */}
          <PatientVisitsTabs patientId={Number(patient.id)} patientName={patient.name} />
          {patient.visits && (
            <Card className="bg-gradient-to-br from-blue-50 to-green-100 shadow-md rounded-lg border-0">
              <CardHeader>
                <CardTitle className="text-green-700 flex items-center gap-2"><Calendar className="w-5 h-5 text-green-400" /> ANC Visits</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-gray-700"><b>Number of Visits:</b> {patient.visits.length}</div>
                {/* Optionally, list visit dates or details here */}
              </CardContent>
            </Card>
          )}
        </div>
      </div>
      {/* View More Button */}
      <div className="flex justify-center pb-8">
        <Button
          className="mt-6 px-8 py-3 text-lg font-semibold bg-gradient-to-r from-blue-600 to-purple-500 text-white rounded-full shadow-lg hover:from-purple-500 hover:to-pink-500 transition"
          onClick={() => {
            if (typeof window !== 'undefined') {
              window.location.href = `/patients/${patient.id}`;
            }
          }}
        >
          View More
        </Button>
      </div>
    </div>
  );
}
