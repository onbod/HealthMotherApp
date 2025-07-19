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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold">Referrals</h1>
          <p className="text-muted-foreground text-sm sm:text-base">List of patient referrals</p>
        </div>
        <Button onClick={() => setShowAdd(true)}>Add Referral</Button>
      </div>
      {/* Dashboard summary */}
      <div className="grid gap-3 sm:gap-4 grid-cols-2 md:grid-cols-4">
        <Card className="bg-gradient-to-br from-green-600 to-green-700 text-white">
          <CardHeader className="text-white">
            <CardTitle className="text-white">Total Referrals</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalReferrals}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-blue-600 to-blue-700 text-white">
          <CardHeader className="text-white">
            <CardTitle className="text-white">Pending</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{pendingReferrals}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-red-600 to-red-700 text-white">
          <CardHeader className="text-white">
            <CardTitle className="text-white">Completed</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{completedReferrals}</div>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-yellow-600 to-yellow-700 text-white">
          <CardHeader className="text-white">
            <CardTitle className="text-white">Unique Patients</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{uniquePatients}</div>
          </CardContent>
        </Card>
      </div>
      {/* Table view for referrals */}
      <div className="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Patient</TableHead>
              <TableHead>Reason</TableHead>
              <TableHead>Date</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {referrals.map((ref) => (
              <TableRow key={ref.id} className="hover:bg-gray-50 cursor-pointer">
                <TableCell>{ref.patient}</TableCell>
                <TableCell>{ref.reason}</TableCell>
                <TableCell>{ref.date}</TableCell>
                <TableCell>
                  <Badge variant={ref.status === "Completed" ? "secondary" : "default"}>{ref.status}</Badge>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
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