"use client"

import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";

const dummyReferrals = [
  { id: "1", patient: "Marie Kamara", reason: "High blood pressure", date: "2024-04-01", status: "Pending" },
  { id: "2", patient: "Sarah Conteh", reason: "Gestational diabetes", date: "2024-04-10", status: "Completed" },
];

export default function ReferralPage() {
  const [referrals, setReferrals] = useState(dummyReferrals);
  const [showAdd, setShowAdd] = useState(false);
  const [newReferral, setNewReferral] = useState({ patient: "", reason: "", date: "", status: "Pending" });

  // Dashboard stats
  const totalReferrals = referrals.length;
  const pendingReferrals = referrals.filter(r => r.status === "Pending").length;
  const completedReferrals = referrals.filter(r => r.status === "Completed").length;
  const uniquePatients = Array.from(new Set(referrals.map(r => r.patient))).length;

  function handleAddReferral(e: React.FormEvent) {
    e.preventDefault();
    setReferrals([
      ...referrals,
      { ...newReferral, id: (referrals.length + 1).toString() },
    ]);
    setShowAdd(false);
    setNewReferral({ patient: "", reason: "", date: "", status: "Pending" });
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold">Referrals</h1>
          <p className="text-muted-foreground text-xs sm:text-sm lg:text-base">List of patient referrals</p>
        </div>
        <Button onClick={() => setShowAdd(true)} className="w-full sm:w-auto shrink-0">Add Referral</Button>
      </div>
      {/* Dashboard summary */}
      <div className="grid gap-3 sm:gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-gradient-to-br from-green-600 to-green-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">Total Referrals</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{totalReferrals}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-blue-600 to-blue-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">Pending</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{pendingReferrals}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-red-600 to-red-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">Completed</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{completedReferrals}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-yellow-600 to-yellow-700 text-white hover:shadow-lg transition-shadow">
          <CardHeader className="text-white px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <CardTitle className="text-white text-xs sm:text-sm font-medium">Unique Patients</CardTitle>
          </CardHeader>
          <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
            <div className="text-2xl sm:text-3xl lg:text-4xl font-bold">{uniquePatients}</div>
          </CardContent>
        </Card>
      </div>
      {/* Table view for referrals - Responsive */}
      <div className="overflow-x-auto -mx-4 sm:mx-0">
        <div className="inline-block min-w-full align-middle px-4 sm:px-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs sm:text-sm">Patient</TableHead>
                <TableHead className="text-xs sm:text-sm hidden md:table-cell">Reason</TableHead>
                <TableHead className="text-xs sm:text-sm">Date</TableHead>
                <TableHead className="text-xs sm:text-sm">Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {referrals.map((ref) => (
                <TableRow key={ref.id} className="hover:bg-gray-50 cursor-pointer">
                  <TableCell className="font-medium text-sm sm:text-base">{ref.patient}</TableCell>
                  <TableCell className="text-xs sm:text-sm hidden md:table-cell">{ref.reason}</TableCell>
                  <TableCell className="text-xs sm:text-sm">{ref.date}</TableCell>
                  <TableCell>
                    <Badge 
                      variant={ref.status === "Completed" ? "secondary" : "default"}
                      className="text-[10px] sm:text-xs"
                    >
                      {ref.status}
                    </Badge>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </div>
      {/* Add Referral Modal */}
      {showAdd && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h2 className="text-xl font-bold mb-4">Add Referral</h2>
            <form className="space-y-3" onSubmit={handleAddReferral}>
              <input className="w-full border rounded px-2 py-1" placeholder="Patient Name" value={newReferral.patient} onChange={e => setNewReferral(r => ({ ...r, patient: e.target.value }))} required />
              <input className="w-full border rounded px-2 py-1" placeholder="Reason" value={newReferral.reason} onChange={e => setNewReferral(r => ({ ...r, reason: e.target.value }))} required />
              <input className="w-full border rounded px-2 py-1" placeholder="Date" type="date" value={newReferral.date} onChange={e => setNewReferral(r => ({ ...r, date: e.target.value }))} required />
              <select className="w-full border rounded px-2 py-1" value={newReferral.status} onChange={e => setNewReferral(r => ({ ...r, status: e.target.value }))}>
                <option value="Pending">Pending</option>
                <option value="Completed">Completed</option>
              </select>
              <div className="flex justify-end gap-2 mt-2">
                <Button type="button" variant="outline" onClick={() => setShowAdd(false)}>Cancel</Button>
                <Button type="submit">Add</Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
} 