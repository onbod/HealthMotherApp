"use client"

import React, { useState, useEffect } from "react"
import { useSearchParams, useRouter, usePathname } from "next/navigation"
import { PatientProfiles } from "../components/patient-profiles"
import { AppointmentCalendar } from "../components/appointment-calendar"
import { AppointmentRequests } from "../components/appointment-requests"
import { PatientDetail } from "../components/patient-detail"
import { DashboardOverview } from "../components/dashboard-overview"
import { AppointmentAnalytics } from "../components/appointment-analytics"
import { Notifications } from "../components/notifications"
import { MedicalRecords } from "../components/medical-records"
import { TrimesterDashboards } from "../components/trimester-dashboards"
import { HealthEducation } from "../components/health-education"
import { Messages } from "../components/messages"
import { useLocalAuth } from "../hooks/use-auth";

export default function Dashboard() {
  const searchParams = useSearchParams()
  const [activeView, setActiveView] = useState("dashboard")
  const [selectedPatient, setSelectedPatient] = useState<string | null>(null)
  const [filteredPatientCount, setFilteredPatientCount] = useState(0)
  const { role, loading } = useLocalAuth();
  const router = useRouter();
  const pathname = usePathname();

  // Update active view based on URL parameters
  useEffect(() => {
    const view = searchParams.get('view') || 'dashboard'
    setActiveView(view)
  }, [searchParams])

  useEffect(() => {
    if (typeof window !== 'undefined') {
      // setRole(localStorage.getItem('userRole') || 'admin'); // This line is removed as per the edit hint
    }
  }, []);

  const handleViewChange = (view: string) => {
    setActiveView(view);
    setSelectedPatient(null)
  }

  const renderContent = () => {
    if (selectedPatient) {
      return <PatientDetail patient={selectedPatient} onBack={() => setSelectedPatient(null)} />
    }

    // Route for clinicians
    if (role === 'clinician') {
      if (pathname === '/patients') {
        const PatientsPage = require('../components/patients').default;
        return <PatientsPage />;
      }
      if (pathname === '/referral') {
        const ReferralPage = require('../components/referral').default;
        return <ReferralPage />;
      }
      const ClinicianDashboard = require('../components/clinician-dashboard').ClinicianDashboard;
      return <ClinicianDashboard />;
    }

    switch (activeView) {
      case "dashboard":
        return <DashboardOverview />
      case "messages":
        return <Messages />
      case "patients":
        return <PatientProfiles onSelectPatient={setSelectedPatient} setFilteredPatientCount={setFilteredPatientCount} />
      case "trimester-views":
        return <TrimesterDashboards onSelectPatient={setSelectedPatient} />
      case "health-education":
        return <HealthEducation />
      case "requests":
        return <AppointmentRequests />
      case "analytics":
        return <AppointmentAnalytics />
      case "notifications":
        return <Notifications />
      case "records":
        return <MedicalRecords />
      default:
        return <DashboardOverview />
    }
  }

  if (loading) return <div className="min-h-screen flex items-center justify-center">Loading...</div>;
  if (!role) return null; // Let layout show the login page

  return renderContent();
}
