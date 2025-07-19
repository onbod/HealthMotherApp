"use client"

import { useState } from "react"
import {
  Heart,
  Baby,
  Activity,
  Eye,
  FileText,
  Filter,
  Search,
  ChevronDown,
  ChevronUp,
  Calendar,
  Phone,
  Users,
  AlertTriangle,
  TrendingUp,
  BarChart3,
  Target,
  CheckCircle,
} from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Progress } from "@/components/ui/progress"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import {
  BarChart,
  Bar,
  PieChart as RechartsPieChart,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
  Area,
  AreaChart,
  Legend,
} from "recharts"
import { useIsMobile } from "@/hooks/use-mobile"

// Contact schedule based on the provided image
const contactSchedule = [
  { contact: 1, gestationalAge: "≤12 weeks", timing: "1st trimester", minWeeks: 0, maxWeeks: 12 },
  { contact: 2, gestationalAge: "13-16 weeks", timing: "2nd trimester", minWeeks: 13, maxWeeks: 16 },
  { contact: 3, gestationalAge: "20 weeks", timing: "2nd trimester", minWeeks: 19, maxWeeks: 21 },
  { contact: 4, gestationalAge: "26 weeks", timing: "2nd trimester", minWeeks: 25, maxWeeks: 27 },
  { contact: 5, gestationalAge: "30 weeks", timing: "3rd trimester", minWeeks: 29, maxWeeks: 31 },
  { contact: 6, gestationalAge: "34 weeks", timing: "3rd trimester", minWeeks: 33, maxWeeks: 35 },
  { contact: 7, gestationalAge: "36 weeks", timing: "3rd trimester", minWeeks: 35, maxWeeks: 37 },
  { contact: 8, gestationalAge: "38-40 weeks", timing: "3rd trimester", minWeeks: 38, maxWeeks: 40 },
]

// Enhanced patient data with contact information
const allPatientsData = [
  {
    id: "1",
    name: "Sarah Chen",
    age: 28,
    weeks: 12,
    trimester: "1st",
    riskLevel: "Low",
    lastVisit: "2024-01-10",
    nextAppointment: "2024-02-10",
    symptoms: ["Morning sickness", "Fatigue"],
    vitals: { bp: "110/70", heartRate: 68, weight: "128 lbs", bmi: 22.1 },
    labResults: { hcg: "Normal", hemoglobin: "13.2 g/dL", glucose: 85 },
    compliance: 95,
    contacts: [1],
    totalContacts: 1,
    phone: "+1-555-0123",
    email: "sarah.chen@email.com",
    dueDate: "2024-08-15",
    registrationDate: "2024-01-05",
  },
  {
    id: "2",
    name: "Amanda Foster",
    age: 32,
    weeks: 8,
    trimester: "1st",
    riskLevel: "Medium",
    lastVisit: "2024-01-22",
    nextAppointment: "2024-02-12",
    symptoms: ["Severe nausea", "Spotting"],
    vitals: { bp: "125/80", heartRate: 75, weight: "132 lbs", bmi: 23.5 },
    labResults: { hcg: "Elevated", hemoglobin: "12.8 g/dL", glucose: 92 },
    compliance: 88,
    contacts: [1],
    totalContacts: 1,
    phone: "+1-555-0124",
    email: "amanda.foster@email.com",
    dueDate: "2024-09-20",
    registrationDate: "2024-01-15",
  },
  {
    id: "3",
    name: "Emma Thompson",
    age: 29,
    weeks: 24,
    trimester: "2nd",
    riskLevel: "Low",
    lastVisit: "2024-01-15",
    nextAppointment: "2024-02-01",
    symptoms: ["Back pain", "Heartburn"],
    vitals: { bp: "118/76", heartRate: 72, weight: "158 lbs", bmi: 24.8 },
    labResults: { glucose: "95 mg/dL", hemoglobin: "12.5 g/dL" },
    compliance: 98,
    fetalMovement: "Active",
    contacts: [1, 2, 3],
    totalContacts: 3,
    phone: "+1-555-0125",
    email: "emma.thompson@email.com",
    dueDate: "2024-06-10",
    registrationDate: "2023-12-01",
  },
  {
    id: "4",
    name: "Lisa Anderson",
    age: 35,
    weeks: 18,
    trimester: "2nd",
    riskLevel: "High",
    lastVisit: "2024-01-12",
    nextAppointment: "2024-02-08",
    symptoms: ["Gestational diabetes", "Hypertension"],
    vitals: { bp: "135/88", heartRate: 82, weight: "175 lbs", bmi: 28.2 },
    labResults: { glucose: "145 mg/dL", hemoglobin: "11.5 g/dL" },
    compliance: 85,
    fetalMovement: "Normal",
    contacts: [1, 2],
    totalContacts: 2,
    phone: "+1-555-0126",
    email: "lisa.anderson@email.com",
    dueDate: "2024-07-15",
    registrationDate: "2023-11-20",
  },
  {
    id: "5",
    name: "Maria Rodriguez",
    age: 26,
    weeks: 36,
    trimester: "3rd",
    riskLevel: "Medium",
    lastVisit: "2024-01-20",
    nextAppointment: "2024-01-27",
    symptoms: ["Braxton Hicks", "Swelling"],
    vitals: { bp: "125/82", heartRate: 78, weight: "165 lbs", bmi: 26.1 },
    labResults: { hemoglobin: "11.8 g/dL", protein: "Trace", glucose: 98 },
    compliance: 92,
    cervicalStatus: "Closed",
    fetalPosition: "Vertex",
    contacts: [1, 2, 3, 4, 5, 6, 7],
    totalContacts: 7,
    phone: "+1-555-0127",
    email: "maria.rodriguez@email.com",
    dueDate: "2024-03-01",
    registrationDate: "2023-07-15",
  },
  {
    id: "6",
    name: "Rachel Kim",
    age: 31,
    weeks: 32,
    trimester: "3rd",
    riskLevel: "Low",
    lastVisit: "2024-01-25",
    nextAppointment: "2024-02-15",
    symptoms: ["Shortness of breath", "Insomnia"],
    vitals: { bp: "120/75", heartRate: 76, weight: "155 lbs", bmi: 24.3 },
    labResults: { hemoglobin: "12.2 g/dL", protein: "Negative", glucose: 88 },
    compliance: 96,
    cervicalStatus: "Closed",
    fetalPosition: "Vertex",
    contacts: [1, 2, 3, 4, 5, 6],
    totalContacts: 6,
    phone: "+1-555-0128",
    email: "rachel.kim@email.com",
    dueDate: "2024-04-05",
    registrationDate: "2023-08-10",
  },
  {
    id: "7",
    name: "Jennifer Walsh",
    age: 27,
    weeks: 16,
    trimester: "2nd",
    riskLevel: "Low",
    lastVisit: "2024-01-18",
    nextAppointment: "2024-02-20",
    symptoms: ["Mild nausea", "Energy increase"],
    vitals: { bp: "115/72", heartRate: 70, weight: "142 lbs", bmi: 23.1 },
    labResults: { glucose: "88 mg/dL", hemoglobin: "13.0 g/dL" },
    compliance: 94,
    fetalMovement: "Not yet",
    contacts: [1, 2],
    totalContacts: 2,
    phone: "+1-555-0129",
    email: "jennifer.walsh@email.com",
    dueDate: "2024-07-30",
    registrationDate: "2023-12-15",
  },
  {
    id: "8",
    name: "Ashley Brown",
    age: 33,
    weeks: 38,
    trimester: "3rd",
    riskLevel: "Low",
    lastVisit: "2024-01-28",
    nextAppointment: "2024-02-04",
    symptoms: ["Pelvic pressure", "Frequent urination"],
    vitals: { bp: "122/78", heartRate: 74, weight: "168 lbs", bmi: 25.7 },
    labResults: { hemoglobin: "12.0 g/dL", protein: "Negative", glucose: 91 },
    compliance: 97,
    cervicalStatus: "1cm dilated",
    fetalPosition: "Vertex",
    contacts: [1, 2, 3, 4, 5, 6, 7, 8],
    totalContacts: 8,
    phone: "+1-555-0130",
    email: "ashley.brown@email.com",
    dueDate: "2024-02-20",
    registrationDate: "2023-06-25",
  },
  {
    id: "9",
    name: "Nicole Davis",
    age: 24,
    weeks: 10,
    trimester: "1st",
    riskLevel: "Low",
    lastVisit: "2024-01-30",
    nextAppointment: "2024-02-28",
    symptoms: ["Mild fatigue", "Breast tenderness"],
    vitals: { bp: "108/65", heartRate: 66, weight: "125 lbs", bmi: 21.8 },
    labResults: { hcg: "Normal", hemoglobin: "13.5 g/dL", glucose: 82 },
    compliance: 91,
    contacts: [1],
    totalContacts: 1,
    phone: "+1-555-0131",
    email: "nicole.davis@email.com",
    dueDate: "2024-09-05",
    registrationDate: "2024-01-25",
  },
  {
    id: "10",
    name: "Samantha Wilson",
    age: 30,
    weeks: 22,
    trimester: "2nd",
    riskLevel: "Low",
    lastVisit: "2024-01-26",
    nextAppointment: "2024-02-23",
    symptoms: ["Round ligament pain", "Increased appetite"],
    vitals: { bp: "116/74", heartRate: 71, weight: "152 lbs", bmi: 24.1 },
    labResults: { glucose: "89 mg/dL", hemoglobin: "12.8 g/dL" },
    compliance: 96,
    fetalMovement: "Active",
    contacts: [1, 2, 3],
    totalContacts: 3,
    phone: "+1-555-0132",
    email: "samantha.wilson@email.com",
    dueDate: "2024-06-25",
    registrationDate: "2023-11-30",
  },
]

type SortField = "name" | "age" | "weeks" | "riskLevel" | "totalContacts" | "compliance" | "lastVisit"
type SortDirection = "asc" | "desc"

interface TrimesterDashboardsProps {
  onSelectPatient?: (patientId: string) => void
}

const calculateMissedContacts = (patient: any) => {
  const missed = []
  for (let i = 1; i <= 8; i++) {
    if (!patient.contacts.includes(i)) {
      missed.push(i)
    }
  }
  return { missed, missedCount: missed.length }
}

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

export function TrimesterDashboards({ onSelectPatient }: TrimesterDashboardsProps) {
  const [activeTab, setActiveTab] = useState("first")
  const [searchTerm, setSearchTerm] = useState("")
  const [contactFilter, setContactFilter] = useState("all")
  const [riskFilter, setRiskFilter] = useState("all")
  const [sortField, setSortField] = useState<SortField>("name")
  const [sortDirection, setSortDirection] = useState<SortDirection>("asc")
  const isMobile = useIsMobile()

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case "High":
        return "destructive"
      case "Medium":
        return "secondary"
      default:
        return "outline"
    }
  }

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc")
    } else {
      setSortField(field)
      setSortDirection("asc")
    }
  }

  const SortIcon = ({ field }: { field: SortField }) => {
    if (sortField !== field) return null
    return sortDirection === "asc" ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />
  }

  const getFilteredAndSortedPatients = (trimester: string) => {
    const filtered = allPatientsData.filter((patient) => {
      // Filter by trimester
      if (trimester === "first" && patient.trimester !== "1st") return false
      if (trimester === "second" && patient.trimester !== "2nd") return false
      if (trimester === "third" && patient.trimester !== "3rd") return false

      // Filter by search term
      if (searchTerm && !patient.name.toLowerCase().includes(searchTerm.toLowerCase())) return false

      // Filter by contact number
      if (contactFilter !== "all") {
        const contactNum = Number.parseInt(contactFilter)
        if (!patient.contacts.includes(contactNum)) return false
      }

      // Filter by risk level
      if (riskFilter !== "all" && patient.riskLevel !== riskFilter) return false

      return true
    })

    // Sort patients
    filtered.sort((a, b) => {
      let aValue: any = a[sortField]
      let bValue: any = b[sortField]

      if (sortField === "lastVisit") {
        aValue = new Date(aValue).getTime()
        bValue = new Date(bValue).getTime()
      }

      if (typeof aValue === "string") {
        aValue = aValue.toLowerCase()
        bValue = bValue.toLowerCase()
      }

      if (sortDirection === "asc") {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0
      }
    })

    return filtered
  }

  const getTrimesterAnalytics = (trimester: string) => {
    const patients = allPatientsData.filter((p) => {
      if (trimester === "first") return p.trimester === "1st"
      if (trimester === "second") return p.trimester === "2nd"
      if (trimester === "third") return p.trimester === "3rd"
      return false
    })

    const totalPatients = patients.length
    const averageAge = patients.reduce((sum, p) => sum + p.age, 0) / totalPatients || 0
    const averageWeeks = patients.reduce((sum, p) => sum + p.weeks, 0) / totalPatients || 0
    const averageCompliance = patients.reduce((sum, p) => sum + p.compliance, 0) / totalPatients || 0

    const riskDistribution = {
      Low: patients.filter((p) => p.riskLevel === "Low").length,
      Medium: patients.filter((p) => p.riskLevel === "Medium").length,
      High: patients.filter((p) => p.riskLevel === "High").length,
    }

    const ageGroups = {
      "18-24": patients.filter((p) => p.age >= 18 && p.age <= 24).length,
      "25-29": patients.filter((p) => p.age >= 25 && p.age <= 29).length,
      "30-34": patients.filter((p) => p.age >= 30 && p.age <= 34).length,
      "35+": patients.filter((p) => p.age >= 35).length,
    }

    const contactCompletion = contactSchedule
      .filter((c) => c.timing.includes(trimester === "first" ? "1st" : trimester === "second" ? "2nd" : "3rd"))
      .map((contact) => ({
        contact: contact.contact,
        gestationalAge: contact.gestationalAge,
        completed: patients.filter((p) => p.contacts.includes(contact.contact)).length,
        total: patients.length,
        percentage:
          patients.length > 0
            ? (patients.filter((p) => p.contacts.includes(contact.contact)).length / patients.length) * 100
            : 0,
      }))

    const weeklyDistribution = patients.reduce(
      (acc, patient) => {
        const weekRange = Math.floor(patient.weeks / 4) * 4
        const key = `${weekRange}-${weekRange + 3}`
        acc[key] = (acc[key] || 0) + 1
        return acc
      },
      {} as Record<string, number>,
    )

    return {
      totalPatients,
      averageAge: Math.round(averageAge * 10) / 10,
      averageWeeks: Math.round(averageWeeks * 10) / 10,
      averageCompliance: Math.round(averageCompliance),
      riskDistribution,
      ageGroups,
      contactCompletion,
      weeklyDistribution,
      patients,
    }
  }

  const DashboardView = ({ trimester }: { trimester: string }) => {
    const analytics = getTrimesterAnalytics(trimester)
    const trimesterName = trimester === "first" ? "First" : trimester === "second" ? "Second" : "Third"

    const riskData = Object.entries(analytics.riskDistribution).map(([risk, count]) => ({
      name: risk,
      value: count,
      percentage: analytics.totalPatients > 0 ? Math.round((count / analytics.totalPatients) * 100) : 0,
    }))

    const ageData = Object.entries(analytics.ageGroups).map(([group, count]) => ({
      name: group,
      value: count,
      percentage: analytics.totalPatients > 0 ? Math.round((count / analytics.totalPatients) * 100) : 0,
    }))

    const weeklyData = Object.entries(analytics.weeklyDistribution).map(([range, count]) => ({
      range,
      patients: count,
    }))

    const complianceData = analytics.patients.map((patient) => ({
      name: patient.name.split(" ")[0],
      compliance: patient.compliance,
      weeks: patient.weeks,
    }))

    const COLORS = ["hsl(var(--chart-1))", "hsl(var(--chart-2))", "hsl(var(--chart-3))", "hsl(var(--chart-4))"]

    return (
      <div className="space-y-6">
        {/* KPI Cards */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Patients</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{analytics.totalPatients}</div>
              <p className="text-xs text-muted-foreground">{trimesterName} trimester patients</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Average Age</CardTitle>
              <Heart className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{analytics.averageAge} years</div>
              <p className="text-xs text-muted-foreground">Mean maternal age</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Average Gestational Age</CardTitle>
              <Calendar className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{analytics.averageWeeks} weeks</div>
              <p className="text-xs text-muted-foreground">Mean gestational age</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Average Compliance</CardTitle>
              <CheckCircle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{analytics.averageCompliance}%</div>
              <p className="text-xs text-muted-foreground">Treatment adherence</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Patients with Missed Contacts</CardTitle>
              <AlertTriangle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {analytics.patients.filter((p) => calculateMissedContacts(p).missedCount > 0).length}
              </div>
              <p className="text-xs text-muted-foreground">
                {analytics.totalPatients > 0
                  ? Math.round(
                      (analytics.patients.filter((p) => calculateMissedContacts(p).missedCount > 0).length /
                        analytics.totalPatients) *
                        100,
                    )
                  : 0}
                % of patients
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Charts Row 1 */}
        <div className="grid gap-6 md:grid-cols-2">
          {/* Risk Distribution */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="h-5 w-5" />
                Risk Level Distribution
              </CardTitle>
              <CardDescription>Patient risk assessment breakdown</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer
                config={{
                  Low: { label: "Low Risk", color: "hsl(var(--chart-1))" },
                  Medium: { label: "Medium Risk", color: "hsl(var(--chart-2))" },
                  High: { label: "High Risk", color: "hsl(var(--chart-3))" },
                }}
                className="h-[300px]"
              >
                <ResponsiveContainer width="100%" height="100%">
                  <RechartsPieChart>
                    <ChartTooltip content={<ChartTooltipContent />} />
                    <RechartsPieChart>
                      <RechartsPieChart dataKey="value" data={riskData} cx="50%" cy="50%" outerRadius={80}>
                        {riskData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </RechartsPieChart>
                    </RechartsPieChart>
                    <Legend />
                  </RechartsPieChart>
                </ResponsiveContainer>
              </ChartContainer>
              <div className="mt-4 space-y-2">
                {riskData.map((item, index) => (
                  <div key={item.name} className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[index] }} />
                      <span>{item.name} Risk</span>
                    </div>
                    <span className="font-medium">
                      {item.value} ({item.percentage}%)
                    </span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Age Distribution */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart3 className="h-5 w-5" />
                Age Group Distribution
              </CardTitle>
              <CardDescription>Maternal age demographics</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer
                config={{
                  patients: { label: "Patients", color: "hsl(var(--chart-1))" },
                }}
                className="h-[300px]"
              >
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={ageData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <ChartTooltip content={<ChartTooltipContent />} />
                    <Bar dataKey="value" fill="var(--color-patients)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </ChartContainer>
            </CardContent>
          </Card>
        </div>

        {/* Charts Row 2 */}
        <div className="grid gap-6 md:grid-cols-2">
          {/* Contact Completion */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Target className="h-5 w-5" />
                Contact Completion Rates
              </CardTitle>
              <CardDescription>Prenatal visit attendance by contact number</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {analytics.contactCompletion.map((contact) => (
                  <div key={contact.contact} className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="font-medium">
                        Contact {contact.contact} ({contact.gestationalAge})
                      </span>
                      <span>
                        {contact.completed}/{contact.total} ({Math.round(contact.percentage)}%)
                      </span>
                    </div>
                    <Progress value={contact.percentage} className="h-2" />
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Compliance Tracking */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="h-5 w-5" />
                Patient Compliance Tracking
              </CardTitle>
              <CardDescription>Individual patient adherence rates</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer
                config={{
                  compliance: { label: "Compliance %", color: "hsl(var(--chart-2))" },
                }}
                className="h-[300px]"
              >
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={complianceData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis domain={[0, 100]} />
                    <ChartTooltip content={<ChartTooltipContent />} />
                    <Area
                      type="monotone"
                      dataKey="compliance"
                      stroke="var(--color-compliance)"
                      fill="var(--color-compliance)"
                      fillOpacity={0.3}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </ChartContainer>
            </CardContent>
          </Card>
        </div>

        {/* Weekly Distribution */}
        {weeklyData.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="h-5 w-5" />
                Gestational Age Distribution
              </CardTitle>
              <CardDescription>Patient distribution by gestational week ranges</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer
                config={{
                  patients: { label: "Patients", color: "hsl(var(--chart-3))" },
                }}
                className="h-[300px]"
              >
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={weeklyData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="range" />
                    <YAxis />
                    <ChartTooltip content={<ChartTooltipContent />} />
                    <Bar dataKey="patients" fill="var(--color-patients)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </ChartContainer>
            </CardContent>
          </Card>
        )}
      </div>
    )
  }

  const PatientTable = ({ trimester }: { trimester: string }) => {
    const patients = getFilteredAndSortedPatients(trimester)

    return (
      <div className="space-y-4">
        {/* Filters */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Filter className="h-5 w-5" />
              Filters & Search
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-4">
              <div className="space-y-2">
                <Label htmlFor="search">Search Patients</Label>
                <div className="relative">
                  <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="search"
                    placeholder="Search by name..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-8"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="contact-filter">Filter by Contact</Label>
                <Select value={contactFilter} onValueChange={setContactFilter}>
                  <SelectTrigger>
                    <SelectValue placeholder="All contacts" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Contacts</SelectItem>
                    {contactSchedule.map((contact) => (
                      <SelectItem key={contact.contact} value={contact.contact.toString()}>
                        Contact {contact.contact} ({contact.gestationalAge})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="risk-filter">Filter by Risk Level</Label>
                <Select value={riskFilter} onValueChange={setRiskFilter}>
                  <SelectTrigger>
                    <SelectValue placeholder="All risk levels" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Risk Levels</SelectItem>
                    <SelectItem value="Low">Low Risk</SelectItem>
                    <SelectItem value="Medium">Medium Risk</SelectItem>
                    <SelectItem value="High">High Risk</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Results</Label>
                <div className="flex items-center gap-2 pt-2">
                  <Badge variant="outline">{patients.length} patients found</Badge>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Patient Table */}
        <Card>
          <CardHeader>
            <CardTitle>Patient Information</CardTitle>
            <CardDescription>Detailed patient data with sorting and filtering capabilities</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[200px]">
                      <Button variant="ghost" onClick={() => handleSort("name")} className="h-auto p-0 font-semibold">
                        Patient Name
                        <SortIcon field="name" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button variant="ghost" onClick={() => handleSort("age")} className="h-auto p-0 font-semibold">
                        Age
                        <SortIcon field="age" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button variant="ghost" onClick={() => handleSort("weeks")} className="h-auto p-0 font-semibold">
                        Gestational Age
                        <SortIcon field="weeks" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        onClick={() => handleSort("totalContacts")}
                        className="h-auto p-0 font-semibold"
                      >
                        Contacts
                        <SortIcon field="totalContacts" />
                      </Button>
                    </TableHead>
                    <TableHead>Missed Contacts</TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        onClick={() => handleSort("riskLevel")}
                        className="h-auto p-0 font-semibold"
                      >
                        Risk Level
                        <SortIcon field="riskLevel" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        onClick={() => handleSort("compliance")}
                        className="h-auto p-0 font-semibold"
                      >
                        Compliance
                        <SortIcon field="compliance" />
                      </Button>
                    </TableHead>
                    <TableHead>Last Visit</TableHead>
                    <TableHead>Contact Info</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {patients.map((patient) => (
                    <TableRow key={patient.id}>
                      <TableCell>
                        <div className="flex items-center space-x-3">
                          <Avatar className="h-8 w-8">
                            <AvatarImage src={`/placeholder.svg?height=32&width=32`} />
                            <AvatarFallback className="text-xs">
                              {getInitials(patient.name)}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="font-medium">{patient.name}</p>
                            <p className="text-xs text-muted-foreground">ID: {patient.id}</p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{patient.age} years</TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium">{patient.weeks} weeks</p>
                          <p className="text-xs text-muted-foreground">{patient.trimester} trimester</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1">
                          {patient.contacts.map((contact) => (
                            <Badge key={contact} variant="outline" className="text-xs">
                              C{contact}
                            </Badge>
                          ))}
                        </div>
                        <p className="text-xs text-muted-foreground mt-1">{patient.totalContacts} total</p>
                      </TableCell>
                      <TableCell>
                        {(() => {
                          const missedInfo = calculateMissedContacts(patient)
                          return (
                            <div>
                              {missedInfo.missedCount > 0 ? (
                                <div className="space-y-1">
                                  <div className="flex flex-wrap gap-1">
                                    {missedInfo.missed.map((contact) => (
                                      <Badge key={contact} variant="destructive" className="text-xs">
                                        C{contact}
                                      </Badge>
                                    ))}
                                  </div>
                                  <p className="text-xs text-red-600 font-medium">{missedInfo.missedCount} missed</p>
                                </div>
                              ) : (
                                <div className="flex items-center gap-1">
                                  <CheckCircle className="h-4 w-4 text-green-600" />
                                  <span className="text-xs text-green-600 font-medium">Up to date</span>
                                </div>
                              )}
                            </div>
                          )
                        })()}
                      </TableCell>
                      <TableCell>
                        <Badge variant={getRiskColor(patient.riskLevel) as any}>{patient.riskLevel}</Badge>
                      </TableCell>
                      <TableCell>
                        <div className="w-16">
                          <Progress value={patient.compliance} className="h-2" />
                          <p className="text-xs text-center mt-1">{patient.compliance}%</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="text-sm">{new Date(patient.lastVisit).toLocaleDateString()}</p>
                          <p className="text-xs text-muted-foreground">
                            Next: {new Date(patient.nextAppointment).toLocaleDateString()}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="space-y-1">
                          <div className="flex items-center gap-1 text-xs">
                            <Phone className="h-3 w-3" />
                            <span className="truncate">{patient.phone}</span>
                          </div>
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <span className="truncate">{patient.email}</span>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="outline" size="sm">
                              Actions
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuLabel>Patient Actions</DropdownMenuLabel>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem onClick={() => onSelectPatient?.(patient.id)}>
                              <Eye className="h-4 w-4 mr-2" />
                              View Details
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              <Calendar className="h-4 w-4 mr-2" />
                              Schedule Appointment
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              <Phone className="h-4 w-4 mr-2" />
                              Contact Patient
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              <FileText className="h-4 w-4 mr-2" />
                              View Records
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>

        {/* Contact Schedule Reference */}
        <Card></Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold">Trimester-Specific Dashboards</h1>
          <p className="text-muted-foreground text-sm sm:text-base">
            Comprehensive analytics and patient management with interactive visualizations
          </p>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="first" className="flex items-center gap-2">
            <Heart className="h-4 w-4" />
            1st Trimester
          </TabsTrigger>
          <TabsTrigger value="second" className="flex items-center gap-2">
            <Activity className="h-4 w-4" />
            2nd Trimester
          </TabsTrigger>
          <TabsTrigger value="third" className="flex items-center gap-2">
            <Baby className="h-4 w-4" />
            3rd Trimester
          </TabsTrigger>
        </TabsList>

        <TabsContent value="first">
          <Tabs defaultValue="dashboard" className="space-y-4">
            <TabsList>
              <TabsTrigger value="dashboard" className="flex items-center gap-2">
                <BarChart3 className="h-4 w-4" />
                Dashboard
              </TabsTrigger>
              <TabsTrigger value="patients" className="flex items-center gap-2">
                <Users className="h-4 w-4" />
                Patient Table
              </TabsTrigger>
            </TabsList>
            <TabsContent value="dashboard">
              <DashboardView trimester="first" />
            </TabsContent>
            <TabsContent value="patients">
              <PatientTable trimester="first" />
            </TabsContent>
          </Tabs>
        </TabsContent>

        <TabsContent value="second">
          <Tabs defaultValue="dashboard" className="space-y-4">
            <TabsList>
              <TabsTrigger value="dashboard" className="flex items-center gap-2">
                <BarChart3 className="h-4 w-4" />
                Dashboard
              </TabsTrigger>
              <TabsTrigger value="patients" className="flex items-center gap-2">
                <Users className="h-4 w-4" />
                Patient Table
              </TabsTrigger>
            </TabsList>
            <TabsContent value="dashboard">
              <DashboardView trimester="second" />
            </TabsContent>
            <TabsContent value="patients">
              <PatientTable trimester="second" />
            </TabsContent>
          </Tabs>
        </TabsContent>

        <TabsContent value="third">
          <Tabs defaultValue="dashboard" className="space-y-4">
            <TabsList>
              <TabsTrigger value="dashboard" className="flex items-center gap-2">
                <BarChart3 className="h-4 w-4" />
                Dashboard
              </TabsTrigger>
              <TabsTrigger value="patients" className="flex items-center gap-2">
                <Users className="h-4 w-4" />
                Patient Table
              </TabsTrigger>
            </TabsList>
            <TabsContent value="dashboard">
              <DashboardView trimester="third" />
            </TabsContent>
            <TabsContent value="patients">
              <PatientTable trimester="third" />
            </TabsContent>
          </Tabs>
        </TabsContent>
      </Tabs>
    </div>
  )
}
