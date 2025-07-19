"use client";
import { useState, useEffect } from "react";
import ReportList from "@/components/report";
import SharedLayout from "@/components/shared-layout";

export default function ReportPage() {
  const [patientCount, setPatientCount] = useState(0);

  useEffect(() => {
    async function fetchPatientCount() {
      try {
        // Replace any Firestore usage with static dummy data or useState.
        setPatientCount(100); // Example static count
      } catch (error) {
        console.error("Error fetching patient count:", error);
        setPatientCount(0);
      }
    }
    fetchPatientCount();
  }, []);

  return (
    <SharedLayout activeView="report" patientCount={patientCount}>
      <ReportList />
    </SharedLayout>
  );
} 