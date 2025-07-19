"use client"

import { Check, X, Clock, Calendar, User, Phone } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

const pendingRequests = [
  {
    id: "1",
    patientName: "Lisa Anderson",
    patientPhone: "(555) 987-6543",
    requestedDate: "2024-02-05",
    requestedTime: "10:00 AM",
    appointmentType: "Prenatal Check-up",
    urgency: "Routine",
    reason: "Regular 28-week prenatal check-up",
    submittedAt: "2024-01-25 09:30 AM",
  },
  {
    id: "2",
    patientName: "Amanda Foster",
    patientPhone: "(555) 876-5432",
    requestedDate: "2024-02-03",
    requestedTime: "2:00 PM",
    appointmentType: "Urgent Consultation",
    urgency: "Urgent",
    reason: "Experiencing unusual symptoms - severe morning sickness",
    submittedAt: "2024-01-25 11:15 AM",
  },
  {
    id: "3",
    patientName: "Rachel Kim",
    patientPhone: "(555) 765-4321",
    requestedDate: "2024-02-07",
    requestedTime: "11:00 AM",
    appointmentType: "First Prenatal Visit",
    urgency: "Routine",
    reason: "First prenatal appointment - 8 weeks pregnant",
    submittedAt: "2024-01-25 02:45 PM",
  },
]

export function AppointmentRequests() {
  // Get initials from first and last name
  const getInitials = (fullName: string) => {
    if (!fullName) return "?";
    const nameParts = fullName.trim().split(' ');
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    } else if (nameParts.length === 1) {
      return nameParts[0][0].toUpperCase();
    }
    return "?";
  };

  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case "Urgent":
        return "destructive"
      case "Priority":
        return "secondary"
      default:
        return "outline"
    }
  }

  const handleAccept = (requestId: string) => {
    console.log("Accepting request:", requestId)
    // Handle accept logic
  }

  const handleDecline = (requestId: string) => {
    console.log("Declining request:", requestId)
    // Handle decline logic
  }

  const handleReschedule = (requestId: string) => {
    console.log("Rescheduling request:", requestId)
    // Handle reschedule logic
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Appointment Requests</h1>
          <p className="text-muted-foreground">Review and manage pending appointment requests</p>
        </div>
        <Badge variant="secondary" className="text-sm">
          {pendingRequests.length} Pending
        </Badge>
      </div>

      <div className="space-y-4">
        {pendingRequests.map((request) => (
          <Card key={request.id} className="hover:shadow-md transition-shadow">
            <CardHeader>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <Avatar>
                    <AvatarImage src={`/placeholder.svg?height=40&width=40`} />
                    <AvatarFallback>
                      {getInitials(request.patientName)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <CardTitle className="text-lg">{request.patientName}</CardTitle>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Phone className="h-3 w-3" />
                      <span>{request.patientPhone}</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <Badge variant={getUrgencyColor(request.urgency) as any}>{request.urgency}</Badge>
                  <Badge variant="outline">{request.appointmentType}</Badge>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4 text-muted-foreground" />
                    <span className="font-medium">Requested Date & Time</span>
                  </div>
                  <p className="text-sm ml-6">
                    {new Date(request.requestedDate).toLocaleDateString()} at {request.requestedTime}
                  </p>
                </div>
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4 text-muted-foreground" />
                    <span className="font-medium">Submitted</span>
                  </div>
                  <p className="text-sm ml-6">{request.submittedAt}</p>
                </div>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-muted-foreground" />
                  <span className="font-medium">Reason for Visit</span>
                </div>
                <p className="text-sm ml-6 text-muted-foreground">{request.reason}</p>
              </div>

              <div className="flex items-center justify-between pt-4 border-t">
                <div className="flex space-x-2">
                  <Button
                    size="sm"
                    onClick={() => handleAccept(request.id)}
                    className="bg-green-600 hover:bg-green-700"
                  >
                    <Check className="h-4 w-4 mr-1" />
                    Accept
                  </Button>
                  <Button variant="outline" size="sm" onClick={() => handleReschedule(request.id)}>
                    <Calendar className="h-4 w-4 mr-1" />
                    Reschedule
                  </Button>
                  <Button variant="destructive" size="sm" onClick={() => handleDecline(request.id)}>
                    <X className="h-4 w-4 mr-1" />
                    Decline
                  </Button>
                </div>
                <Button variant="ghost" size="sm">
                  View Patient Profile
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {pendingRequests.length === 0 && (
        <Card>
          <CardContent className="text-center py-12">
            <Clock className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-medium mb-2">No Pending Requests</h3>
            <p className="text-muted-foreground">All appointment requests have been processed.</p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
