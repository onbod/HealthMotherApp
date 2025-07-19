"use client"

import { useState } from "react"
import { ChevronLeft, ChevronRight, Plus, Clock, User } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"

const appointments = [
  {
    id: "1",
    patientName: "Emma Thompson",
    date: "2024-02-01",
    time: "10:00 AM",
    type: "Prenatal Check-up",
    duration: "30 min",
    status: "Confirmed",
  },
  {
    id: "2",
    patientName: "Maria Rodriguez",
    date: "2024-02-01",
    time: "2:00 PM",
    type: "Ultrasound",
    duration: "45 min",
    status: "Confirmed",
  },
  {
    id: "3",
    patientName: "Sarah Chen",
    date: "2024-02-02",
    time: "9:00 AM",
    type: "First Prenatal Visit",
    duration: "60 min",
    status: "Confirmed",
  },
  {
    id: "4",
    patientName: "Jennifer Wilson",
    date: "2024-02-02",
    time: "11:00 AM",
    type: "Postpartum Check-up",
    duration: "30 min",
    status: "Confirmed",
  },
]

export function AppointmentCalendar() {
  const [currentDate, setCurrentDate] = useState(new Date())

  const formatDate = (date: Date) => {
    return date.toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    })
  }

  const getTypeColor = (type: string) => {
    switch (type) {
      case "Prenatal Check-up":
        return "default"
      case "Ultrasound":
        return "secondary"
      case "First Prenatal Visit":
        return "outline"
      case "Postpartum Check-up":
        return "destructive"
      default:
        return "default"
    }
  }

  const todayAppointments = appointments.filter(
    (apt) => new Date(apt.date).toDateString() === currentDate.toDateString(),
  )

  const tomorrowAppointments = appointments.filter((apt) => {
    const tomorrow = new Date(currentDate)
    tomorrow.setDate(tomorrow.getDate() + 1)
    return new Date(apt.date).toDateString() === tomorrow.toDateString()
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Appointment Calendar</h1>
          <p className="text-muted-foreground">Manage patient visits and scheduling</p>
        </div>
        
      </div>

      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <Button variant="outline" size="icon">
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <h2 className="text-xl font-semibold">{formatDate(currentDate)}</h2>
          <Button variant="outline" size="icon">
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
        <div className="flex space-x-2">
          <Button variant="outline" size="sm">
            Day
          </Button>
          <Button variant="outline" size="sm">
            Week
          </Button>
          <Button variant="default" size="sm">
            Month
          </Button>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5" />
              Today's Appointments
            </CardTitle>
          </CardHeader>
          <CardContent>
            {todayAppointments.length === 0 ? (
              <p className="text-muted-foreground text-center py-8">No appointments scheduled for today</p>
            ) : (
              <div className="space-y-4">
                {todayAppointments.map((appointment) => (
                  <div
                    key={appointment.id}
                    className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex items-center space-x-3">
                      <div className="flex flex-col">
                        <span className="font-medium text-sm">{appointment.time}</span>
                        <span className="text-xs text-muted-foreground">{appointment.duration}</span>
                      </div>
                      <div className="h-8 w-px bg-gray-200" />
                      <div>
                        <p className="font-medium">{appointment.patientName}</p>
                        <p className="text-sm text-muted-foreground">{appointment.type}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Badge variant={getTypeColor(appointment.type) as any}>{appointment.status}</Badge>
                      <Button variant="outline" size="sm">
                        Reschedule
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-5 w-5" />
              Tomorrow's Appointments
            </CardTitle>
          </CardHeader>
          <CardContent>
            {tomorrowAppointments.length === 0 ? (
              <p className="text-muted-foreground text-center py-8">No appointments scheduled for tomorrow</p>
            ) : (
              <div className="space-y-4">
                {tomorrowAppointments.map((appointment) => (
                  <div
                    key={appointment.id}
                    className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex items-center space-x-3">
                      <div className="flex flex-col">
                        <span className="font-medium text-sm">{appointment.time}</span>
                        <span className="text-xs text-muted-foreground">{appointment.duration}</span>
                      </div>
                      <div className="h-8 w-px bg-gray-200" />
                      <div>
                        <p className="font-medium">{appointment.patientName}</p>
                        <p className="text-sm text-muted-foreground">{appointment.type}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Badge variant={getTypeColor(appointment.type) as any}>{appointment.status}</Badge>
                      <Button variant="outline" size="sm">
                        Reschedule
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Weekly Overview</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-7 gap-2">
            {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day, index) => (
              <div key={day} className="text-center">
                <div className="font-medium text-sm mb-2">{day}</div>
                <div className="h-24 border rounded-lg p-2 bg-gray-50">
                  {index < 2 && (
                    <div className="text-xs space-y-1">
                      <div className="bg-blue-100 text-blue-800 px-1 py-0.5 rounded text-xs">
                        {index === 0 ? "2 appts" : "1 appt"}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
