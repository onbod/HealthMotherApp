"use client"

import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

const dummyReferrals = [
  { id: "1", patient: "Marie Kamara", reason: "High blood pressure", date: "2024-04-01", status: "Pending" },
  { id: "2", patient: "Sarah Conteh", reason: "Gestational diabetes", date: "2024-04-10", status: "Completed" },
];

export default function ReferralPage() {
  const [referrals, setReferrals] = useState(dummyReferrals);
  const [showAdd, setShowAdd] = useState(false);
  const [newReferral, setNewReferral] = useState({ patient: "", reason: "", date: "", status: "Pending" });

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
      <div className="grid gap-3 sm:gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
        {referrals.map((ref) => (
          <Card key={ref.id}>
            <CardHeader>
              <CardTitle>{ref.patient}</CardTitle>
            </CardHeader>
            <CardContent>
              <div>Reason: {ref.reason}</div>
              <div>Date: {ref.date}</div>
              <div>Status: {ref.status}</div>
            </CardContent>
          </Card>
        ))}
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