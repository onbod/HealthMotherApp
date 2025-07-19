"use client"

import { useState } from "react"
import { TrendingUp, TrendingDown, Calendar, Clock, Users, AlertTriangle, CheckCircle, XCircle } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import {
  Bar,
  BarChart,
  Line,
  LineChart,
  Pie,
  PieChart,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
  Legend,
  Area,
  AreaChart,
} from "recharts"

// Sample data for appointment analytics
const appointmentStatusData = [
  { status: "Completed", count: 156, percentage: 78, fill: "#10b981" },
  { status: "No-Show", count: 24, percentage: 12, fill: "#ef4444" },
  { status: "Cancelled", count: 16, percentage: 8, fill: "#f59e0b" },
  { status: "Rescheduled", count: 4, percentage: 2, fill: "#8b5cf6" },
]

const monthlyTrends = [
  { month: "Aug", completed: 45, noShow: 8, cancelled: 5, rescheduled: 2 },
  { month: "Sep", completed: 52, noShow: 6, cancelled: 4, rescheduled: 3 },
  { month: "Oct", completed: 48, noShow: 9, cancelled: 6, rescheduled: 1 },
  { month: "Nov", completed: 58, noShow: 7, cancelled: 3, rescheduled: 2 },
  { month: "Dec", completed: 61, noShow: 5, cancelled: 4, rescheduled: 3 },
  { month: "Jan", completed: 67, noShow: 4, cancelled: 2, rescheduled: 1 },
]

const dayOfWeekAnalytics = [
  { day: "Monday", completed: 28, noShow: 4, cancelled: 2, noShowRate: 12.5 },
  { day: "Tuesday", completed: 32, noShow: 3, cancelled: 1, noShowRate: 8.6 },
  { day: "Wednesday", completed: 25, noShow: 6, cancelled: 3, noShowRate: 17.6 },
  { day: "Thursday", completed: 30, noShow: 2, cancelled: 2, noShowRate: 6.3 },
  { day: "Friday", completed: 26, noShow: 5, cancelled: 4, noShowRate: 14.3 },
]

const timeSlotAnalytics = [
  { time: "8:00 AM", completed: 18, noShow: 2, cancelled: 1, noShowRate: 9.5 },
  { time: "10:00 AM", completed: 22, noShow: 1, cancelled: 1, noShowRate: 4.2 },
  { time: "12:00 PM", completed: 20, noShow: 4, cancelled: 2, noShowRate: 15.4 },
  { time: "2:00 PM", completed: 25, noShow: 3, cancelled: 1, noShowRate: 10.3 },
  { time: "4:00 PM", completed: 19, noShow: 5, cancelled: 3, noShowRate: 18.5 },
]

const appointmentTypeAnalytics = [
  { type: "Prenatal Check-up", completed: 89, noShow: 12, cancelled: 6, total: 107 },
  { type: "Ultrasound", completed: 34, noShow: 3, cancelled: 2, total: 39 },
  { type: "First Visit", completed: 18, noShow: 6, cancelled: 4, total: 28 },
  { type: "Postpartum", completed: 15, noShow: 3, cancelled: 4, total: 22 },
]

const patientNoShowAnalytics = [
  { name: "Sarah Wilson", noShows: 3, totalAppointments: 8, rate: 37.5, risk: "High" },
  { name: "Maria Garcia", noShows: 2, totalAppointments: 6, rate: 33.3, risk: "Medium" },
  { name: "Jennifer Lee", noShows: 2, totalAppointments: 9, rate: 22.2, risk: "Medium" },
  { name: "Amanda Foster", noShows: 1, totalAppointments: 5, rate: 20.0, risk: "Low" },
]

const cancellationReasons = [
  { reason: "Illness", count: 8, percentage: 33.3 },
  { reason: "Emergency", count: 6, percentage: 25.0 },
  { reason: "Schedule Conflict", count: 5, percentage: 20.8 },
  { reason: "Transportation", count: 3, percentage: 12.5 },
  { reason: "Other", count: 2, percentage: 8.3 },
]

export function AppointmentAnalytics() {
  const [selectedTimeframe, setSelectedTimeframe] = useState("6months")

  const totalAppointments = appointmentStatusData.reduce((sum, item) => sum + item.count, 0)
  const noShowRate = (
    ((appointmentStatusData.find((item) => item.status === "No-Show")?.count || 0) / totalAppointments) *
    100
  ).toFixed(1)
  const cancellationRate = (
    ((appointmentStatusData.find((item) => item.status === "Cancelled")?.count || 0) / totalAppointments) *
    100
  ).toFixed(1)

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Appointment Analytics</h1>
          <p className="text-muted-foreground">Detailed insights into appointment patterns and patient behavior</p>
        </div>
        <div className="flex space-x-2">
          <Button
            variant={selectedTimeframe === "3months" ? "default" : "outline"}
            size="sm"
            onClick={() => setSelectedTimeframe("3months")}
          >
            3 Months
          </Button>
          <Button
            variant={selectedTimeframe === "6months" ? "default" : "outline"}
            size="sm"
            onClick={() => setSelectedTimeframe("6months")}
          >
            6 Months
          </Button>
          <Button
            variant={selectedTimeframe === "1year" ? "default" : "outline"}
            size="sm"
            onClick={() => setSelectedTimeframe("1year")}
          >
            1 Year
          </Button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Appointments</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalAppointments}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-green-600 flex items-center">
                <TrendingUp className="h-3 w-3 mr-1" />
                +15% from last period
              </span>
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">No-Show Rate</CardTitle>
            <XCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{noShowRate}%</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-green-600 flex items-center">
                <TrendingDown className="h-3 w-3 mr-1" />
                -2.3% from last period
              </span>
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Cancellation Rate</CardTitle>
            <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{cancellationRate}%</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-red-600 flex items-center">
                <TrendingUp className="h-3 w-3 mr-1" />
                +1.2% from last period
              </span>
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Completion Rate</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">78%</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-green-600 flex items-center">
                <TrendingUp className="h-3 w-3 mr-1" />
                +3.1% from last period
              </span>
            </p>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="trends">Trends</TabsTrigger>
          <TabsTrigger value="patterns">Patterns</TabsTrigger>
          <TabsTrigger value="patients">Patient Analysis</TabsTrigger>
          <TabsTrigger value="insights">Insights</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-2">
            {/* Appointment Status Distribution */}
            <Card>
              <CardHeader>
                <CardTitle>Appointment Status Distribution</CardTitle>
                <CardDescription>Overall appointment outcomes for the selected period</CardDescription>
              </CardHeader>
              <CardContent>
                <ChartContainer
                  config={{
                    count: {
                      label: "Appointments",
                      color: "hsl(var(--chart-1))",
                    },
                  }}
                  className="h-[300px]"
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={appointmentStatusData}
                        cx="50%"
                        cy="50%"
                        outerRadius={80}
                        dataKey="count"
                        label={({ status, percentage }) => `${status}: ${percentage}%`}
                      >
                        {appointmentStatusData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.fill} />
                        ))}
                      </Pie>
                      <ChartTooltip content={<ChartTooltipContent />} />
                    </PieChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </CardContent>
            </Card>

            {/* Appointment Type Analysis */}
            <Card>
              <CardHeader>
                <CardTitle>Performance by Appointment Type</CardTitle>
                <CardDescription>Completion rates across different appointment types</CardDescription>
              </CardHeader>
              <CardContent>
                <ChartContainer
                  config={{
                    completed: {
                      label: "Completed",
                      color: "hsl(var(--chart-1))",
                    },
                    noShow: {
                      label: "No-Show",
                      color: "hsl(var(--chart-2))",
                    },
                    cancelled: {
                      label: "Cancelled",
                      color: "hsl(var(--chart-3))",
                    },
                  }}
                  className="h-[300px]"
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={appointmentTypeAnalytics}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="type" angle={-45} textAnchor="end" height={80} />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Legend />
                      <Bar dataKey="completed" stackId="a" fill="var(--color-completed)" />
                      <Bar dataKey="noShow" stackId="a" fill="var(--color-noShow)" />
                      <Bar dataKey="cancelled" stackId="a" fill="var(--color-cancelled)" />
                    </BarChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="trends" className="space-y-6">
          <div className="grid gap-6">
            {/* Monthly Trends */}
            <Card>
              <CardHeader>
                <CardTitle>Monthly Appointment Trends</CardTitle>
                <CardDescription>Track appointment outcomes over time</CardDescription>
              </CardHeader>
              <CardContent>
                <ChartContainer
                  config={{
                    completed: {
                      label: "Completed",
                      color: "hsl(var(--chart-1))",
                    },
                    noShow: {
                      label: "No-Show",
                      color: "hsl(var(--chart-2))",
                    },
                    cancelled: {
                      label: "Cancelled",
                      color: "hsl(var(--chart-3))",
                    },
                  }}
                  className="h-[400px]"
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={monthlyTrends}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Legend />
                      <Area
                        type="monotone"
                        dataKey="completed"
                        stackId="1"
                        stroke="var(--color-completed)"
                        fill="var(--color-completed)"
                      />
                      <Area
                        type="monotone"
                        dataKey="noShow"
                        stackId="1"
                        stroke="var(--color-noShow)"
                        fill="var(--color-noShow)"
                      />
                      <Area
                        type="monotone"
                        dataKey="cancelled"
                        stackId="1"
                        stroke="var(--color-cancelled)"
                        fill="var(--color-cancelled)"
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="patterns" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-2">
            {/* Day of Week Analysis */}
            <Card>
              <CardHeader>
                <CardTitle>No-Show Rates by Day of Week</CardTitle>
                <CardDescription>Identify patterns in patient attendance</CardDescription>
              </CardHeader>
              <CardContent>
                <ChartContainer
                  config={{
                    noShowRate: {
                      label: "No-Show Rate (%)",
                      color: "hsl(var(--chart-2))",
                    },
                  }}
                  className="h-[300px]"
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={dayOfWeekAnalytics}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="day" />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Bar dataKey="noShowRate" fill="var(--color-noShowRate)" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </CardContent>
            </Card>

            {/* Time Slot Analysis */}
            <Card>
              <CardHeader>
                <CardTitle>No-Show Rates by Time Slot</CardTitle>
                <CardDescription>Optimize scheduling based on attendance patterns</CardDescription>
              </CardHeader>
              <CardContent>
                <ChartContainer
                  config={{
                    noShowRate: {
                      label: "No-Show Rate (%)",
                      color: "hsl(var(--chart-3))",
                    },
                  }}
                  className="h-[300px]"
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={timeSlotAnalytics}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="time" />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Line
                        type="monotone"
                        dataKey="noShowRate"
                        stroke="var(--color-noShowRate)"
                        strokeWidth={3}
                        dot={{ r: 6 }}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </CardContent>
            </Card>
          </div>

          {/* Cancellation Reasons */}
          <Card>
            <CardHeader>
              <CardTitle>Cancellation Reasons</CardTitle>
              <CardDescription>Understanding why patients cancel appointments</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {cancellationReasons.map((reason, index) => (
                  <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex items-center space-x-3">
                      <div className="w-3 h-3 rounded-full bg-blue-500" />
                      <span className="font-medium">{reason.reason}</span>
                    </div>
                    <div className="flex items-center space-x-3">
                      <span className="text-sm text-muted-foreground">{reason.count} cancellations</span>
                      <Badge variant="outline">{reason.percentage.toFixed(1)}%</Badge>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="patients" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>High No-Show Risk Patients</CardTitle>
              <CardDescription>Patients with concerning attendance patterns</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {patientNoShowAnalytics.map((patient, index) => (
                  <div key={index} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-3">
                      <div className="flex flex-col">
                        <span className="font-medium">{patient.name}</span>
                        <span className="text-sm text-muted-foreground">
                          {patient.noShows} no-shows out of {patient.totalAppointments} appointments
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center space-x-3">
                      <div className="text-right">
                        <p className="font-medium">{patient.rate.toFixed(1)}%</p>
                        <p className="text-sm text-muted-foreground">No-show rate</p>
                      </div>
                      <Badge
                        variant={
                          patient.risk === "High" ? "destructive" : patient.risk === "Medium" ? "secondary" : "outline"
                        }
                      >
                        {patient.risk} Risk
                      </Badge>
                      <Button variant="outline" size="sm">
                        Contact
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="insights" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Key Insights</CardTitle>
                <CardDescription>Actionable recommendations based on your data</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-start space-x-3 p-3 bg-green-50 rounded-lg">
                  <CheckCircle className="h-5 w-5 text-green-600 mt-0.5" />
                  <div>
                    <p className="font-medium text-green-800">Improved Completion Rate</p>
                    <p className="text-sm text-green-700">
                      Your completion rate has improved by 3.1% this period, indicating better patient engagement.
                    </p>
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-3 bg-yellow-50 rounded-lg">
                  <AlertTriangle className="h-5 w-5 text-yellow-600 mt-0.5" />
                  <div>
                    <p className="font-medium text-yellow-800">Wednesday No-Show Peak</p>
                    <p className="text-sm text-yellow-700">
                      Wednesday has the highest no-show rate (17.6%). Consider reminder calls for Wednesday
                      appointments.
                    </p>
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-3 bg-blue-50 rounded-lg">
                  <Clock className="h-5 w-5 text-blue-600 mt-0.5" />
                  <div>
                    <p className="font-medium text-blue-800">Late Afternoon Challenges</p>
                    <p className="text-sm text-blue-700">
                      4:00 PM slots have higher no-show rates. Consider offering earlier alternatives.
                    </p>
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-3 bg-red-50 rounded-lg">
                  <Users className="h-5 w-5 text-red-600 mt-0.5" />
                  <div>
                    <p className="font-medium text-red-800">High-Risk Patients</p>
                    <p className="text-sm text-red-700">
                      4 patients have no-show rates above 20%. Consider implementing a follow-up protocol.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Recommendations</CardTitle>
                <CardDescription>Strategies to improve appointment attendance</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="p-3 border rounded-lg">
                    <h4 className="font-medium mb-2">Implement Reminder System</h4>
                    <p className="text-sm text-muted-foreground">
                      Send automated reminders 24-48 hours before appointments, especially for Wednesday slots.
                    </p>
                  </div>

                  <div className="p-3 border rounded-lg">
                    <h4 className="font-medium mb-2">Patient Education Program</h4>
                    <p className="text-sm text-muted-foreground">
                      Educate patients about the importance of regular prenatal visits and the impact of missed
                      appointments.
                    </p>
                  </div>

                  <div className="p-3 border rounded-lg">
                    <h4 className="font-medium mb-2">Flexible Scheduling</h4>
                    <p className="text-sm text-muted-foreground">
                      Offer more morning slots and reduce late afternoon appointments to improve attendance rates.
                    </p>
                  </div>

                  <div className="p-3 border rounded-lg">
                    <h4 className="font-medium mb-2">High-Risk Patient Protocol</h4>
                    <p className="text-sm text-muted-foreground">
                      Develop a special follow-up protocol for patients with high no-show rates, including personal
                      calls.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
