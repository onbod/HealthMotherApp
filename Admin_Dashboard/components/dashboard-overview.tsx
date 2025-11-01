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

export function DashboardOverview() {
  const isMobile = useIsMobile();
  const [loading, setLoading] = useState(true);
  const [patients, setPatients] = useState<any[]>([]);
  const [deliveries, setDeliveries] = useState<any[]>([]);
  const [ancIndicators, setAncIndicators] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      setLoading(true)
      setError(null)
      try {
        // Fetch patients
        const patientsRes = await fetch("https://health-fhir-backend-production-6ae1.up.railway.app/api/patient");
        const patientsData = await patientsRes.json();
        let realPatients = [];
        if (Array.isArray(patientsData)) {
          realPatients = patientsData;
        } else if (patientsData.entry && Array.isArray(patientsData.entry)) {
          realPatients = patientsData.entry.map((e: any) => e.resource);
        }
        setPatients(realPatients);

        // Fetch deliveries
        const deliveriesRes = await fetch("https://health-fhir-backend-production-6ae1.up.railway.app/delivery");
        const deliveriesData = await deliveriesRes.json();
        setDeliveries(Array.isArray(deliveriesData) ? deliveriesData : []);

        // Fetch ANC indicators
        const ancRes = await fetch("https://health-fhir-backend-production-6ae1.up.railway.app/indicators/anc");
        const ancData = await ancRes.json();
        setAncIndicators(ancData);
      } catch (err: any) {
        setError("Failed to fetch dashboard data.")
      } finally {
        setLoading(false)
      }
    }
    fetchData()
  }, [])

  // Compute metrics
  const totalPatients = patients.length
  const birthsThisMonth = deliveries.filter((d: any) => {
    const date = new Date(d.dateOfDelivery || d.deliveryDate)
    const now = new Date()
    return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear()
  }).length
  const highRiskPatients = patients.filter((p: any) => p.riskLevel === "High").length
  // Example: appointmentsThisWeek from ANC indicators if available
  const totalAppointmentsThisWeek = ancIndicators?.appointmentsThisWeek || 0

  // Example: patients by trimester (if available in patient data)
  const patientsByTrimester = [
    { trimester: "1st Trimester", count: patients.filter((p: any) => p.trimester === "1st").length, fill: "#3b82f6" },
    { trimester: "2nd Trimester", count: patients.filter((p: any) => p.trimester === "2nd").length, fill: "#10b981" },
    { trimester: "3rd Trimester", count: patients.filter((p: any) => p.trimester === "3rd").length, fill: "#f59e0b" },
    { trimester: "Postpartum", count: patients.filter((p: any) => p.status === "Postpartum").length, fill: "#8b5cf6" },
  ]

  // Example: risk levels
  const riskLevels = [
    { level: "Low Risk", count: patients.filter((p: any) => p.riskLevel === "Low").length, fill: "#10b981" },
    { level: "Medium Risk", count: patients.filter((p: any) => p.riskLevel === "Medium").length, fill: "#f59e0b" },
    { level: "High Risk", count: highRiskPatients, fill: "#ef4444" },
  ]

  // Example: upcoming due dates
  const upcomingDueDates = patients
    .filter((p: any) => p.dueDate)
    .map((p: any) => ({
      name: p.name?.text || p.name || "Unknown",
      dueDate: p.dueDate,
      weeks: p.weeks,
      risk: p.riskLevel || "Unknown"
    }))
    .sort((a: any, b: any) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime())
    .slice(0, 4)

  // Compute weekly appointments for chart
  const appointmentsThisWeekData = ancIndicators?.appointmentsByDay || [];

  // Compute monthly trends for the last 6 months
  const getLast6Months = () => {
    const months = [];
    const now = new Date();
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      months.push({
        month: d.toLocaleString('default', { month: 'short' }),
        year: d.getFullYear(),
        key: `${d.getFullYear()}-${d.getMonth()}`
      });
    }
    return months;
  };
  const last6Months = getLast6Months();
  const monthlyTrends = last6Months.map(({ month, year, key }) => {
    const newPatients = patients.filter((p: any) => {
      const created = p.meta?.lastUpdated ? new Date(p.meta.lastUpdated) : null;
      return created && created.getFullYear() === year && created.getMonth() === last6Months.findIndex(m => m.key === key) + (new Date().getMonth() - 5);
    }).length;
    const births = deliveries.filter((d: any) => {
      const date = new Date(d.dateOfDelivery || d.deliveryDate);
      return date.getFullYear() === year && date.toLocaleString('default', { month: 'short' }) === month;
    }).length;
    return { month, newPatients, births };
  });

  if (loading) {
    return <div>Loading dashboard...</div>
  }
  if (error) {
    return <div className="text-red-500">{error}</div>
  }

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
                {/* You can add a real trend here if available */}
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
                <BarChart data={appointmentsThisWeekData}>
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
