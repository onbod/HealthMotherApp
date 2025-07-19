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
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
      <div className="flex items-center gap-4">
        <Button variant="outline" size="icon" onClick={onBack}>
              <ArrowLeft className="h-5 w-5" />
          </Button>
          <div>
              <h1 className="text-3xl font-bold text-gray-900">{patient.name}</h1>
              <p className="text-gray-600">Patient Medical Record</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Badge variant={patient.status === "Delivered" ? "secondary" : patient.status === "Active" ? "default" : "secondary"} className="text-sm">
              {patient.status || "-"}
            </Badge>
            <Badge variant={patient.riskLevel === 'High' ? 'destructive' : patient.riskLevel === 'Medium' ? 'default' : 'secondary'} className="text-sm">
              {patient.riskLevel || "-"} Risk
            </Badge>
          </div>
        </div>
      </div>
      {/* Main Content */}
      <div className="flex flex-col md:flex-row gap-6 p-6">
        {/* Left Sidebar - Demographics & Contact */}
        <div className="w-full md:w-1/3 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Demographics</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div><b>Patient ID:</b> {patient.id}</div>
                <div><b>Age:</b> {patient.age ?? "-"}</div>
                <div><b>Date of Birth:</b> {patient.birthDate ?? "-"}</div>
              </div>
            </CardContent>
          </Card>
                <Card>
                  <CardHeader>
              <CardTitle>Contact Information</CardTitle>
                </CardHeader>
                <CardContent>
                            <div className="space-y-2">
                <div><Phone className="inline w-4 h-4 mr-1" /> {patient.phone ?? "-"}</div>
                <div><Mail className="inline w-4 h-4 mr-1" /> {patient.email ?? "-"}</div>
                <div><b>Address:</b> {patient.address ?? "-"}</div>
                <div><b>Emergency Contact:</b> {patient.emergencyContact ?? "-"}</div>
                    </div>
                  </CardContent>
                </Card>
        </div>
        {/* Right Content - Pregnancy & Visits */}
        <div className="w-full md:w-2/3 space-y-4">
                  <Card>
                    <CardHeader>
              <CardTitle>Pregnancy Status</CardTitle>
                    </CardHeader>
                    <CardContent>
              <div className="grid grid-cols-2 gap-4">
                <div><b>Weeks:</b> {patient.weeks ?? "-"}</div>
                <div><b>Trimester:</b> {patient.weeks !== undefined ? (patient.weeks <= 12 ? "1st trimester" : patient.weeks <= 27 ? "2nd trimester" : "3rd trimester") : "-"}</div>
                <div><b>Due Date:</b> {patient.dueDate ?? "-"}</div>
                      </div>
                    </CardContent>
                  </Card>
          {patient.visits && (
                    <Card>
                      <CardHeader>
                <CardTitle>ANC Visits</CardTitle>
                      </CardHeader>
                      <CardContent>
                <div><b>Number of Visits:</b> {patient.visits.length}</div>
                {/* Optionally, list visit dates or details here */}
                      </CardContent>
                    </Card>
                  )}
                </div>
      </div>
    </div>
  );
}
