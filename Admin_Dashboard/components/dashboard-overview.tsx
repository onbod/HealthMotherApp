"use client"

import { TrendingUp, TrendingDown, Users, Calendar, AlertTriangle, Baby, Clock } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
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
} from "recharts"
import { useIsMobile } from "@/hooks/use-mobile"
import { useEffect, useState } from "react"

// Sample data for charts
const patientsByTrimester = [
  { trimester: "1st Trimester", count: 8, fill: "#3b82f6" },
  { trimester: "2nd Trimester", count: 12, fill: "#10b981" },
  { trimester: "3rd Trimester", count: 6, fill: "#f59e0b" },
  { trimester: "Postpartum", count: 4, fill: "#8b5cf6" },
]

const appointmentsThisWeek = [
  { day: "Mon", appointments: 6 },
  { day: "Tue", appointments: 8 },
  { day: "Wed", appointments: 5 },
  { day: "Thu", appointments: 9 },
  { day: "Fri", appointments: 7 },
  { day: "Sat", appointments: 3 },
  { day: "Sun", appointments: 2 },
]

const riskLevels = [
  { level: "Low Risk", count: 18, fill: "#10b981" },
  { level: "Medium Risk", count: 8, fill: "#f59e0b" },
  { level: "High Risk", count: 4, fill: "#ef4444" },
]

const monthlyTrends = [
  { month: "Aug", newPatients: 4, births: 2 },
  { month: "Sep", newPatients: 6, births: 3 },
  { month: "Oct", newPatients: 5, births: 4 },
  { month: "Nov", newPatients: 8, births: 3 },
  { month: "Dec", newPatients: 7, births: 5 },
  { month: "Jan", newPatients: 9, births: 4 },
]

const upcomingDueDates = [
  { name: "Marie Kamara", dueDate: "2024-02-15", weeks: 36, risk: "Medium" },
  { name: "Emmanuella Turay", dueDate: "2024-03-20", weeks: 24, risk: "Low" },
  { name: "Sarah Conteh", dueDate: "2024-04-10", weeks: 12, risk: "Low" },
  { name: "Clara Deen", dueDate: "2024-04-25", weeks: 8, risk: "Low" },
]

export function DashboardOverview() {
  const isMobile = useIsMobile()
  // Dummy data for metrics
  const totalPatients = 30
  const highRiskPatients = 4
  const birthsThisMonth = 5
  const totalAppointmentsThisWeek = appointmentsThisWeek.reduce((sum, item) => sum + item.appointments, 0)

  return (
    <div className="space-y-4 sm:space-y-6">
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold">Dashboard Overview</h1>
        <p className="text-muted-foreground text-sm sm:text-base">
          Key metrics and insights for your maternal health practice
        </p>
      </div>

      {/* Key Metrics Cards */}
      <div className="grid gap-3 sm:gap-4 grid-cols-2 lg:grid-cols-4">
        <Card className="bg-gradient-to-br from-green-600 to-green-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Total Patients</CardTitle>
            <Users className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{totalPatients}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-black flex items-center">
                <TrendingUp className="h-3 w-3 mr-1" />
                +12% from last month
              </span>
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-blue-600 to-blue-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">This Week's Appointments</CardTitle>
            <Calendar className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{totalAppointmentsThisWeek}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-black flex items-center">
                <TrendingUp className="h-3 w-3 mr-1" />
                +8% from last week
              </span>
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-red-600 to-red-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">High Risk Patients</CardTitle>
            <AlertTriangle className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{highRiskPatients}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-black flex items-center">
                <TrendingDown className="h-3 w-3 mr-1" />
                -2 from last month
              </span>
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-yellow-600 to-yellow-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Births This Month</CardTitle>
            <Baby className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{birthsThisMonth}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-black flex items-center">
                <TrendingUp className="h-3 w-3 mr-1" />
                0 from last month
              </span>
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Charts Grid */}
      <div className="grid gap-4 sm:gap-6 grid-cols-1 lg:grid-cols-2">
        {/* Patients by Trimester */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base sm:text-lg">Patients by Trimester</CardTitle>
            <CardDescription className="text-sm">
              Current distribution of patients across pregnancy stages
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer
              config={{
                count: {
                  label: "Patients",
                  color: "hsl(var(--chart-1))",
                },
              }}
              className={`${isMobile ? "h-[250px]" : "h-[300px]"} my-0`}
            >
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={patientsByTrimester}
                    cx="50%"
                    cy="50%"
                    outerRadius={isMobile ? 60 : 80}
                    dataKey="count"
                    label={({ trimester, count }) => (isMobile ? `${count}` : `${trimester}: ${count}`)}
                  >
                    {patientsByTrimester.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.fill} />
                    ))}
                  </Pie>
                  <ChartTooltip content={<ChartTooltipContent />} />
                </PieChart>
              </ResponsiveContainer>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Weekly Appointments */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base sm:text-lg">Weekly Appointments</CardTitle>
            <CardDescription className="text-sm">Appointments scheduled for this week</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer
              config={{
                appointments: {
                  label: "Appointments",
                  color: "hsl(var(--chart-2))",
                },
              }}
              className={`${isMobile ? "h-[250px]" : "h-[300px]"}`}
            >
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={appointmentsThisWeek}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="day" fontSize={isMobile ? 10 : 12} />
                  <YAxis fontSize={isMobile ? 10 : 12} />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar dataKey="appointments" fill="var(--color-appointments)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Risk Level Distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base sm:text-lg">Risk Level Distribution</CardTitle>
            <CardDescription className="text-sm">Patient risk assessment overview</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer
              config={{
                count: {
                  label: "Patients",
                  color: "hsl(var(--chart-3))",
                },
              }}
              className={`${isMobile ? "h-[250px]" : "h-[300px]"}`}
            >
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={riskLevels} layout="horizontal">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" fontSize={isMobile ? 10 : 12} />
                  <YAxis dataKey="level" type="category" width={isMobile ? 60 : 80} fontSize={isMobile ? 10 : 12} />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar dataKey="count" radius={[0, 4, 4, 0]}>
                    {riskLevels.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.fill} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Monthly Trends */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base sm:text-lg">Monthly Trends</CardTitle>
            <CardDescription className="text-sm">New patients and births over the last 6 months</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer
              config={{
                newPatients: {
                  label: "New Patients",
                  color: "hsl(var(--chart-1))",
                },
                births: {
                  label: "Births",
                  color: "hsl(var(--chart-2))",
                },
              }}
              className={`${isMobile ? "h-[250px]" : "h-[300px]"}`}
            >
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={monthlyTrends}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" fontSize={isMobile ? 10 : 12} />
                  <YAxis fontSize={isMobile ? 10 : 12} />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="newPatients"
                    stroke="var(--color-newPatients)"
                    strokeWidth={2}
                    dot={{ r: isMobile ? 3 : 4 }}
                  />
                  <Line
                    type="monotone"
                    dataKey="births"
                    stroke="var(--color-births)"
                    strokeWidth={2}
                    dot={{ r: isMobile ? 3 : 4 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </ChartContainer>
          </CardContent>
        </Card>
      </div>

      {/* Upcoming Due Dates */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base sm:text-lg">
            <Clock className="h-4 w-4 sm:h-5 sm:w-5" />
            Upcoming Due Dates
          </CardTitle>
          <CardDescription className="text-sm">Patients with due dates in the next 8 weeks</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {upcomingDueDates.map((patient, index) => (
              <div
                key={index}
                className="flex flex-col sm:flex-row sm:items-center justify-between p-3 border rounded-lg space-y-2 sm:space-y-0"
              >
                <div className="flex items-center space-x-3">
                  <div className="flex flex-col">
                    <span className="font-medium text-sm sm:text-base">{patient.name}</span>
                    <span className="text-xs sm:text-sm text-muted-foreground">{patient.weeks} weeks pregnant</span>
                  </div>
                </div>
                <div className="flex flex-col sm:flex-row sm:items-center space-y-2 sm:space-y-0 sm:space-x-3">
                  <div className="text-left sm:text-right">
                    <p className="font-medium text-sm sm:text-base">{new Date(patient.dueDate).toLocaleDateString()}</p>
                    <p className="text-xs sm:text-sm text-muted-foreground">
                      {Math.ceil((new Date(patient.dueDate).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))}{" "}
                      days
                    </p>
                  </div>
                  <Badge
                    variant={
                      patient.risk === "High" ? "destructive" : patient.risk === "Medium" ? "secondary" : "outline"
                    }
                    className="w-fit"
                  >
                    {patient.risk} Risk
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
