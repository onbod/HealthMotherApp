"use client"

import { useState } from "react"
import {
  FileText,
  Download,
  Printer,
  Search,
  Users,
  Heart,
  Baby,
  AlertTriangle,
  Eye,
  MoreHorizontal,
  FileSpreadsheet,
  FileImage,
} from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer } from "recharts"
import { useIsMobile } from "@/hooks/use-mobile"

// Sample comprehensive patient data
const medicalRecordsData = [
  {
    id: "1",
    name: "Emma Thompson",
    age: 28,
    phone: "(555) 123-4567",
    email: "emma.thompson@email.com",
    address: "123 Oak Street, Springfield, IL 62701",
    emergencyContact: "John Thompson",
    emergencyPhone: "(555) 123-4568",
    pregnancyWeeks: 24,
    trimester: "2nd",
    dueDate: "2024-08-15",
    status: "Active",
    riskLevel: "Low",
    bloodType: "O+",
    height: "5'6\"",
    prePregnancyWeight: "140 lbs",
    currentWeight: "158 lbs",
    bmi: 25.5,
    bloodPressure: "118/76",
    heartRate: 72,
    lastVisit: "2024-01-15",
    nextAppointment: "2024-02-01",
    medicalHistory: ["No chronic conditions", "Previous pregnancy: 2021 (Normal delivery)"],
    allergies: ["No known allergies"],
    currentMedications: ["Prenatal vitamins", "Folic acid 400mcg", "Iron supplement 65mg"],
    labResults: {
      hemoglobin: "12.5 g/dL",
      glucose: "95 mg/dL",
      protein: "Negative",
    },
    insurance: "Blue Cross Blue Shield",
    ethnicity: "Caucasian",
    maritalStatus: "Married",
    occupation: "Teacher",
    education: "Bachelor's Degree",
  },
  {
    id: "2",
    name: "Maria Rodriguez",
    age: 32,
    phone: "(555) 234-5678",
    email: "maria.rodriguez@email.com",
    address: "456 Pine Avenue, Springfield, IL 62702",
    emergencyContact: "Carlos Rodriguez",
    emergencyPhone: "(555) 234-5679",
    pregnancyWeeks: 36,
    trimester: "3rd",
    dueDate: "2024-03-20",
    status: "Active",
    riskLevel: "Medium",
    bloodType: "A+",
    height: "5'4\"",
    prePregnancyWeight: "135 lbs",
    currentWeight: "165 lbs",
    bmi: 28.3,
    bloodPressure: "125/82",
    heartRate: 78,
    lastVisit: "2024-01-20",
    nextAppointment: "2024-01-27",
    medicalHistory: ["Gestational diabetes (previous pregnancy)", "Hypertension"],
    allergies: ["Penicillin"],
    currentMedications: ["Prenatal vitamins", "Metformin", "Low-dose aspirin"],
    labResults: {
      hemoglobin: "11.8 g/dL",
      glucose: "110 mg/dL",
      protein: "Trace",
    },
    insurance: "Aetna",
    ethnicity: "Hispanic",
    maritalStatus: "Married",
    occupation: "Nurse",
    education: "Associate Degree",
  },
  {
    id: "3",
    name: "Sarah Chen",
    age: 26,
    phone: "(555) 345-6789",
    email: "sarah.chen@email.com",
    address: "789 Maple Drive, Springfield, IL 62703",
    emergencyContact: "David Chen",
    emergencyPhone: "(555) 345-6790",
    pregnancyWeeks: 12,
    trimester: "1st",
    dueDate: "2024-09-10",
    status: "Active",
    riskLevel: "Low",
    bloodType: "B+",
    height: "5'5\"",
    prePregnancyWeight: "125 lbs",
    currentWeight: "128 lbs",
    bmi: 21.3,
    bloodPressure: "110/70",
    heartRate: 68,
    lastVisit: "2024-01-10",
    nextAppointment: "2024-02-10",
    medicalHistory: ["No significant medical history"],
    allergies: ["Shellfish"],
    currentMedications: ["Prenatal vitamins", "Folic acid"],
    labResults: {
      hemoglobin: "13.2 g/dL",
      glucose: "88 mg/dL",
      protein: "Negative",
    },
    insurance: "United Healthcare",
    ethnicity: "Asian",
    maritalStatus: "Married",
    occupation: "Software Engineer",
    education: "Master's Degree",
  },
  {
    id: "4",
    name: "Jennifer Wilson",
    age: 35,
    phone: "(555) 456-7890",
    email: "jennifer.wilson@email.com",
    address: "321 Elm Street, Springfield, IL 62704",
    emergencyContact: "Michael Wilson",
    emergencyPhone: "(555) 456-7891",
    pregnancyWeeks: 0,
    trimester: "Postpartum",
    dueDate: "2024-01-05",
    status: "Postpartum",
    riskLevel: "Low",
    bloodType: "AB+",
    height: "5'7\"",
    prePregnancyWeight: "150 lbs",
    currentWeight: "155 lbs",
    bmi: 24.2,
    bloodPressure: "115/75",
    heartRate: 70,
    lastVisit: "2024-01-18",
    nextAppointment: "2024-02-05",
    medicalHistory: ["C-section delivery (2024)", "No complications"],
    allergies: ["No known allergies"],
    currentMedications: ["Iron supplement", "Multivitamin"],
    labResults: {
      hemoglobin: "12.0 g/dL",
      glucose: "92 mg/dL",
      protein: "Negative",
    },
    insurance: "Cigna",
    ethnicity: "Caucasian",
    maritalStatus: "Married",
    occupation: "Marketing Manager",
    education: "Bachelor's Degree",
  },
  {
    id: "5",
    name: "Lisa Anderson",
    age: 29,
    phone: "(555) 567-8901",
    email: "lisa.anderson@email.com",
    address: "654 Cedar Lane, Springfield, IL 62705",
    emergencyContact: "Robert Anderson",
    emergencyPhone: "(555) 567-8902",
    pregnancyWeeks: 18,
    trimester: "2nd",
    dueDate: "2024-07-22",
    status: "Active",
    riskLevel: "High",
    bloodType: "O-",
    height: "5'3\"",
    prePregnancyWeight: "160 lbs",
    currentWeight: "175 lbs",
    bmi: 31.0,
    bloodPressure: "135/88",
    heartRate: 82,
    lastVisit: "2024-01-12",
    nextAppointment: "2024-02-08",
    medicalHistory: ["Type 2 Diabetes", "Obesity", "Previous miscarriage"],
    allergies: ["Latex", "Iodine"],
    currentMedications: ["Insulin", "Prenatal vitamins", "Baby aspirin"],
    labResults: {
      hemoglobin: "11.5 g/dL",
      glucose: "145 mg/dL",
      protein: "1+",
    },
    insurance: "Medicaid",
    ethnicity: "African American",
    maritalStatus: "Single",
    occupation: "Retail Associate",
    education: "High School",
  },
]

// Calculate statistics
const totalPatients = medicalRecordsData.length
const activePatients = medicalRecordsData.filter((p) => p.status === "Active").length
const postpartumPatients = medicalRecordsData.filter((p) => p.status === "Postpartum").length
const highRiskPatients = medicalRecordsData.filter((p) => p.riskLevel === "High").length

const trimesterData = [
  {
    trimester: "1st Trimester",
    count: medicalRecordsData.filter((p) => p.trimester === "1st").length,
    fill: "#3b82f6",
  },
  {
    trimester: "2nd Trimester",
    count: medicalRecordsData.filter((p) => p.trimester === "2nd").length,
    fill: "#10b981",
  },
  {
    trimester: "3rd Trimester",
    count: medicalRecordsData.filter((p) => p.trimester === "3rd").length,
    fill: "#f59e0b",
  },
  { trimester: "Postpartum", count: postpartumPatients, fill: "#8b5cf6" },
]

const ageDistribution = [
  { ageGroup: "18-25", count: medicalRecordsData.filter((p) => p.age >= 18 && p.age <= 25).length },
  { ageGroup: "26-30", count: medicalRecordsData.filter((p) => p.age >= 26 && p.age <= 30).length },
  { ageGroup: "31-35", count: medicalRecordsData.filter((p) => p.age >= 31 && p.age <= 35).length },
  { ageGroup: "36+", count: medicalRecordsData.filter((p) => p.age >= 36).length },
]

const riskDistribution = [
  { risk: "Low", count: medicalRecordsData.filter((p) => p.riskLevel === "Low").length, fill: "#10b981" },
  { risk: "Medium", count: medicalRecordsData.filter((p) => p.riskLevel === "Medium").length, fill: "#f59e0b" },
  { risk: "High", count: medicalRecordsData.filter((p) => p.riskLevel === "High").length, fill: "#ef4444" },
]

export function MedicalRecords() {
  const [searchTerm, setSearchTerm] = useState("")
  const [filterStatus, setFilterStatus] = useState("all")
  const [filterRisk, setFilterRisk] = useState("all")
  const [selectedPatient, setSelectedPatient] = useState<(typeof medicalRecordsData)[0] | null>(null)
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false)
  const [isExportModalOpen, setIsExportModalOpen] = useState(false)
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false)
  const [sortBy, setSortBy] = useState("name")
  const [sortOrder, setSortOrder] = useState("asc")
  const [viewMode, setViewMode] = useState<"cards" | "table">("cards")
  const isMobile = useIsMobile()

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

  // Filter patients based on search and filters
  const filteredPatients = medicalRecordsData.filter((patient) => {
    const matchesSearch =
      patient.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      patient.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      patient.phone.includes(searchTerm)

    const matchesStatus = filterStatus === "all" || patient.status.toLowerCase() === filterStatus
    const matchesRisk = filterRisk === "all" || patient.riskLevel.toLowerCase() === filterRisk

    return matchesSearch && matchesStatus && matchesRisk
  })

  const handleExport = (format: string) => {
    console.log(`Exporting data in ${format} format`)
    // Implementation for different export formats
    switch (format) {
      case "csv":
        exportToCSV()
        break
      case "excel":
        exportToExcel()
        break
      case "pdf":
        exportToPDF()
        break
      default:
        console.log("Unknown format")
    }
  }

  const exportToCSV = () => {
    const headers = [
      "Name",
      "Age",
      "Phone",
      "Email",
      "Status",
      "Trimester",
      "Weeks",
      "Due Date",
      "Risk Level",
      "Blood Type",
      "BMI",
      "Blood Pressure",
      "Last Visit",
    ]

    const csvData = filteredPatients.map((patient) => [
      patient.name,
      patient.age,
      patient.phone,
      patient.email,
      patient.status,
      patient.trimester,
      patient.pregnancyWeeks,
      patient.dueDate,
      patient.riskLevel,
      patient.bloodType,
      patient.bmi,
      patient.bloodPressure,
      patient.lastVisit,
    ])

    const csvContent = [headers, ...csvData].map((row) => row.map((field) => `"${field}"`).join(",")).join("\n")

    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `medical-records-${new Date().toISOString().split("T")[0]}.csv`
    a.click()
    window.URL.revokeObjectURL(url)
  }

  const exportToExcel = () => {
    // Placeholder for Excel export functionality
    alert("Excel export functionality would be implemented here using libraries like xlsx")
  }

  const exportToPDF = () => {
    // Placeholder for PDF export functionality
    alert("PDF export functionality would be implemented here using libraries like jsPDF")
  }

  const handlePrint = () => {
    const printContent = document.getElementById("medical-records-content")
    if (printContent) {
      const printWindow = window.open("", "_blank")
      if (printWindow) {
        printWindow.document.write(`
          <html>
            <head>
              <title>Medical Records Report</title>
              <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f5f5f5; }
                .header { text-align: center; margin-bottom: 30px; }
                .stats { display: flex; justify-content: space-around; margin: 20px 0; }
                .stat-card { text-align: center; padding: 10px; border: 1px solid #ddd; }
                @media print { .no-print { display: none; } }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>Medical Records Report</h1>
                <p>Generated on: ${new Date().toLocaleDateString()}</p>
              </div>
              ${printContent.innerHTML}
            </body>
          </html>
        `)
        printWindow.document.close()
        printWindow.print()
      }
    }
  }

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

  const getStatusColor = (status: string) => {
    switch (status) {
      case "Active":
        return "default"
      case "Postpartum":
        return "secondary"
      default:
        return "outline"
    }
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold">Medical Records</h1>
          <p className="text-muted-foreground text-sm sm:text-base">
            Comprehensive patient data and health metrics overview
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-2">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" className="w-full sm:w-auto">
                <Download className="h-4 w-4 mr-2" />
                Export Data
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuItem onClick={() => handleExport("csv")}>
                <FileSpreadsheet className="h-4 w-4 mr-2" />
                Export as CSV
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => handleExport("excel")}>
                <FileSpreadsheet className="h-4 w-4 mr-2" />
                Export as Excel
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => handleExport("pdf")}>
                <FileImage className="h-4 w-4 mr-2" />
                Export as PDF
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <Button variant="outline" onClick={handlePrint} className="w-full sm:w-auto">
            <Printer className="h-4 w-4 mr-2" />
            Print Report
          </Button>
        </div>
      </div>

      <div id="medical-records-content">
        {/* Key Metrics Cards */}
        <div className="grid gap-3 sm:gap-4 grid-cols-2 lg:grid-cols-4 mb-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-xs sm:text-sm font-medium">Total Patients</CardTitle>
              <Users className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-xl sm:text-2xl font-bold">{totalPatients}</div>
              <p className="text-xs text-muted-foreground">
                {activePatients} active, {postpartumPatients} postpartum
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-xs sm:text-sm font-medium">Active Pregnancies</CardTitle>
              <Heart className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-xl sm:text-2xl font-bold">{activePatients}</div>
              <p className="text-xs text-muted-foreground">Currently under care</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-xs sm:text-sm font-medium">Births Completed</CardTitle>
              <Baby className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-xl sm:text-2xl font-bold">{postpartumPatients}</div>
              <p className="text-xs text-muted-foreground">Postpartum patients</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-xs sm:text-sm font-medium">High Risk Cases</CardTitle>
              <AlertTriangle className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-xl sm:text-2xl font-bold">{highRiskPatients}</div>
              <p className="text-xs text-muted-foreground">Requiring special care</p>
            </CardContent>
          </Card>
        </div>

        {/* Charts Section */}
        <div className="grid gap-4 sm:gap-6 grid-cols-1 lg:grid-cols-3 mb-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base sm:text-lg">Trimester Distribution</CardTitle>
              <CardDescription className="text-sm">Patient distribution by pregnancy stage</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer
                config={{
                  count: { label: "Patients", color: "hsl(var(--chart-1))" },
                }}
                className={`${isMobile ? "h-[200px]" : "h-[250px]"}`}
              >
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={trimesterData}
                      cx="50%"
                      cy="50%"
                      outerRadius={isMobile ? 50 : 70}
                      dataKey="count"
                      label={({ trimester, count }) => (isMobile ? `${count}` : `${trimester}: ${count}`)}
                    >
                      {trimesterData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Pie>
                    <ChartTooltip content={<ChartTooltipContent />} />
                  </PieChart>
                </ResponsiveContainer>
              </ChartContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base sm:text-lg">Age Distribution</CardTitle>
              <CardDescription className="text-sm">Patient age demographics</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer
                config={{
                  count: { label: "Patients", color: "hsl(var(--chart-2))" },
                }}
                className={`${isMobile ? "h-[200px]" : "h-[250px]"}`}
              >
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={ageDistribution}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="ageGroup" fontSize={isMobile ? 10 : 12} />
                    <YAxis fontSize={isMobile ? 10 : 12} />
                    <ChartTooltip content={<ChartTooltipContent />} />
                    <Bar dataKey="count" fill="var(--color-count)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </ChartContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base sm:text-lg">Risk Assessment</CardTitle>
              <CardDescription className="text-sm">Patient risk level distribution</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer
                config={{
                  count: { label: "Patients", color: "hsl(var(--chart-3))" },
                }}
                className={`${isMobile ? "h-[200px]" : "h-[250px]"}`}
              >
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={riskDistribution}
                      cx="50%"
                      cy="50%"
                      outerRadius={isMobile ? 50 : 70}
                      dataKey="count"
                      label={({ risk, count }) => (isMobile ? `${count}` : `${risk}: ${count}`)}
                    >
                      {riskDistribution.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Pie>
                    <ChartTooltip content={<ChartTooltipContent />} />
                  </PieChart>
                </ResponsiveContainer>
              </ChartContainer>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="overview" className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="overview">Patient Overview</TabsTrigger>
            <TabsTrigger value="demographics">Demographics</TabsTrigger>
            <TabsTrigger value="health">Health Metrics</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-4">
            {/* Search and Filter */}
            <div className="flex flex-col sm:flex-row gap-3">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search patients..."
                  className="pl-10"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              <Select value={filterStatus} onValueChange={setFilterStatus}>
                <SelectTrigger className="w-full sm:w-[150px]">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="postpartum">Postpartum</SelectItem>
                </SelectContent>
              </Select>
              <Select value={filterRisk} onValueChange={setFilterRisk}>
                <SelectTrigger className="w-full sm:w-[150px]">
                  <SelectValue placeholder="Risk Level" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Risk Levels</SelectItem>
                  <SelectItem value="low">Low Risk</SelectItem>
                  <SelectItem value="medium">Medium Risk</SelectItem>
                  <SelectItem value="high">High Risk</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Patient Table */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base sm:text-lg">Patient Records</CardTitle>
                <CardDescription className="text-sm">
                  Comprehensive patient information. Showing {filteredPatients.length} of {totalPatients} patients.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {isMobile ? (
                  /* Mobile Card View */
                  <div className="space-y-3">
                    {filteredPatients.map((patient) => (
                      <Card key={patient.id} className="cursor-pointer hover:shadow-md transition-shadow">
                        <CardContent className="p-4">
                          <div className="flex items-start space-x-3">
                            <Avatar className="h-12 w-12">
                              <AvatarImage src={`/placeholder.svg?height=48&width=48`} />
                              <AvatarFallback>
                                {getInitials(patient.name)}
                              </AvatarFallback>
                            </Avatar>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-start justify-between">
                                <div>
                                  <h3 className="font-semibold text-base">{patient.name}</h3>
                                  <p className="text-sm text-muted-foreground">Age: {patient.age}</p>
                                </div>
                                <div className="flex flex-col gap-1">
                                  <Badge variant={getStatusColor(patient.status) as any} className="text-xs">
                                    {patient.status}
                                  </Badge>
                                  <Badge variant={getRiskColor(patient.riskLevel) as any} className="text-xs">
                                    {patient.riskLevel}
                                  </Badge>
                                </div>
                              </div>

                              <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
                                <div>
                                  <span className="font-medium">Trimester:</span> {patient.trimester}
                                </div>
                                <div>
                                  <span className="font-medium">Weeks:</span> {patient.pregnancyWeeks}
                                </div>
                                <div>
                                  <span className="font-medium">Blood Type:</span> {patient.bloodType}
                                </div>
                                <div>
                                  <span className="font-medium">BMI:</span> {patient.bmi}
                                </div>
                              </div>

                              <div className="mt-3 flex justify-end">
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() => {
                                    setSelectedPatient(patient)
                                    setIsDetailModalOpen(true)
                                  }}
                                >
                                  <Eye className="h-4 w-4 mr-1" />
                                  View Details
                                </Button>
                              </div>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                ) : (
                  /* Desktop Table View */
                  <div className="overflow-x-auto">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead className="min-w-[200px]">Patient</TableHead>
                          <TableHead>Age</TableHead>
                          <TableHead>Status</TableHead>
                          <TableHead>Trimester</TableHead>
                          <TableHead>Weeks</TableHead>
                          <TableHead>Risk Level</TableHead>
                          <TableHead>Blood Type</TableHead>
                          <TableHead>BMI</TableHead>
                          <TableHead>Last Visit</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredPatients.map((patient) => (
                          <TableRow
                            key={patient.id}
                            className="cursor-pointer hover:bg-gray-50 transition-colors"
                            onClick={() => {
                              setSelectedPatient(patient);
                              setIsDetailModalOpen(true);
                            }}
                          >
                            <TableCell>
                              <div className="flex items-center space-x-3">
                                <Avatar className="h-8 w-8">
                                  <AvatarImage src={`/placeholder.svg?height=32&width=32`} />
                                  <AvatarFallback className="text-xs">
                                    {getInitials(patient.name)}
                                  </AvatarFallback>
                                </Avatar>
                                <div>
                                  <div className="font-medium">{patient.name}</div>
                                  <div className="text-sm text-muted-foreground">{patient.email}</div>
                                </div>
                              </div>
                            </TableCell>
                            <TableCell>{patient.age}</TableCell>
                            <TableCell>
                              <Badge variant={getStatusColor(patient.status) as any}>{patient.status}</Badge>
                            </TableCell>
                            <TableCell>{patient.trimester}</TableCell>
                            <TableCell>{patient.pregnancyWeeks}</TableCell>
                            <TableCell>
                              <Badge variant={getRiskColor(patient.riskLevel) as any}>{patient.riskLevel}</Badge>
                            </TableCell>
                            <TableCell>{patient.bloodType}</TableCell>
                            <TableCell>{patient.bmi}</TableCell>
                            <TableCell>{new Date(patient.lastVisit).toLocaleDateString()}</TableCell>
                            {/* Actions column removed; row is now clickable */}
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="demographics" className="space-y-4">
            <div className="grid gap-4 sm:gap-6 grid-cols-1 lg:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">Ethnicity Distribution</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {["Caucasian", "Hispanic", "Asian", "African American"].map((ethnicity) => {
                      const count = medicalRecordsData.filter((p) => p.ethnicity === ethnicity).length
                      const percentage = ((count / totalPatients) * 100).toFixed(1)
                      return (
                        <div key={ethnicity} className="flex items-center justify-between">
                          <span className="text-sm">{ethnicity}</span>
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium">{count}</span>
                            <span className="text-xs text-muted-foreground">({percentage}%)</span>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">Education Levels</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {["High School", "Associate Degree", "Bachelor's Degree", "Master's Degree"].map((education) => {
                      const count = medicalRecordsData.filter((p) => p.education === education).length
                      const percentage = ((count / totalPatients) * 100).toFixed(1)
                      return (
                        <div key={education} className="flex items-center justify-between">
                          <span className="text-sm">{education}</span>
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium">{count}</span>
                            <span className="text-xs text-muted-foreground">({percentage}%)</span>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">Insurance Coverage</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {["Blue Cross Blue Shield", "Aetna", "United Healthcare", "Cigna", "Medicaid"].map((insurance) => {
                      const count = medicalRecordsData.filter((p) => p.insurance === insurance).length
                      const percentage = count > 0 ? ((count / totalPatients) * 100).toFixed(1) : "0.0"
                      return (
                        <div key={insurance} className="flex items-center justify-between">
                          <span className="text-sm">{insurance}</span>
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium">{count}</span>
                            <span className="text-xs text-muted-foreground">({percentage}%)</span>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">Marital Status</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {["Married", "Single"].map((status) => {
                      const count = medicalRecordsData.filter((p) => p.maritalStatus === status).length
                      const percentage = ((count / totalPatients) * 100).toFixed(1)
                      return (
                        <div key={status} className="flex items-center justify-between">
                          <span className="text-sm">{status}</span>
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium">{count}</span>
                            <span className="text-xs text-muted-foreground">({percentage}%)</span>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="health" className="space-y-4">
            <div className="grid gap-4 sm:gap-6 grid-cols-1 lg:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">BMI Distribution</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {[
                      { range: "Underweight (<18.5)", min: 0, max: 18.5 },
                      { range: "Normal (18.5-24.9)", min: 18.5, max: 24.9 },
                      { range: "Overweight (25-29.9)", min: 25, max: 29.9 },
                      { range: "Obese (≥30)", min: 30, max: 100 },
                    ].map((category) => {
                      const count = medicalRecordsData.filter(
                        (p) => p.bmi >= category.min && p.bmi < category.max,
                      ).length
                      const percentage = ((count / totalPatients) * 100).toFixed(1)
                      return (
                        <div key={category.range} className="flex items-center justify-between">
                          <span className="text-sm">{category.range}</span>
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium">{count}</span>
                            <span className="text-xs text-muted-foreground">({percentage}%)</span>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">Blood Type Distribution</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-"].map((bloodType) => {
                      const count = medicalRecordsData.filter((p) => p.bloodType === bloodType).length
                      const percentage = count > 0 ? ((count / totalPatients) * 100).toFixed(1) : "0.0"
                      return (
                        <div key={bloodType} className="flex items-center justify-between">
                          <span className="text-sm">{bloodType}</span>
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium">{count}</span>
                            <span className="text-xs text-muted-foreground">({percentage}%)</span>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">Common Medical Conditions</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {["Gestational Diabetes", "Hypertension", "Type 2 Diabetes", "Obesity", "Previous Miscarriage"].map(
                      (condition) => {
                        const count = medicalRecordsData.filter((p) =>
                          p.medicalHistory.some((history) => history.toLowerCase().includes(condition.toLowerCase())),
                        ).length
                        const percentage = count > 0 ? ((count / totalPatients) * 100).toFixed(1) : "0.0"
                        return (
                          <div key={condition} className="flex items-center justify-between">
                            <span className="text-sm">{condition}</span>
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-medium">{count}</span>
                              <span className="text-xs text-muted-foreground">({percentage}%)</span>
                            </div>
                          </div>
                        )
                      },
                    )}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base sm:text-lg">Average Health Metrics</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Average Age</span>
                      <span className="text-sm font-medium">
                        {(medicalRecordsData.reduce((sum, p) => sum + p.age, 0) / totalPatients).toFixed(1)} years
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Average BMI</span>
                      <span className="text-sm font-medium">
                        {(medicalRecordsData.reduce((sum, p) => sum + p.bmi, 0) / totalPatients).toFixed(1)}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Average Heart Rate</span>
                      <span className="text-sm font-medium">
                        {(medicalRecordsData.reduce((sum, p) => sum + p.heartRate, 0) / totalPatients).toFixed(0)} bpm
                      </span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>
        </Tabs>
      </div>

      {/* Patient Detail Modal */}
      <Dialog open={isDetailModalOpen} onOpenChange={setIsDetailModalOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-3">
              <Avatar className="h-10 w-10">
                <AvatarImage src={`/placeholder.svg?height=40&width=40`} />
                <AvatarFallback>
                  {getInitials(selectedPatient?.name)}
                </AvatarFallback>
              </Avatar>
              <div>
                <div className="text-xl font-semibold">{selectedPatient?.name}</div>
                <div className="text-sm text-muted-foreground font-normal">Complete Medical Record</div>
              </div>
            </DialogTitle>
          </DialogHeader>

          {selectedPatient && (
            <div className="space-y-6">
              {/* Basic Information */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Card>
                  <CardHeader>
                    <CardTitle className="text-base">Personal Information</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-2">
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      <div>
                        <span className="font-medium">Age:</span> {selectedPatient.age}
                      </div>
                      <div>
                        <span className="font-medium">Blood Type:</span> {selectedPatient.bloodType}
                      </div>
                      <div>
                        <span className="font-medium">Height:</span> {selectedPatient.height}
                      </div>
                      <div>
                        <span className="font-medium">BMI:</span> {selectedPatient.bmi}
                      </div>
                      <div>
                        <span className="font-medium">Ethnicity:</span> {selectedPatient.ethnicity}
                      </div>
                      <div>
                        <span className="font-medium">Education:</span> {selectedPatient.education}
                      </div>
                    </div>
                    <div className="pt-2">
                      <p className="text-sm">
                        <span className="font-medium">Address:</span> {selectedPatient.address}
                      </p>
                      <p className="text-sm">
                        <span className="font-medium">Phone:</span> {selectedPatient.phone}
                      </p>
                      <p className="text-sm">
                        <span className="font-medium">Email:</span> {selectedPatient.email}
                      </p>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle className="text-base">Pregnancy Status</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-2">
                    <div className="flex gap-2 mb-2">
                      <Badge variant={getStatusColor(selectedPatient.status) as any}>{selectedPatient.status}</Badge>
                      <Badge variant={getRiskColor(selectedPatient.riskLevel) as any}>
                        {selectedPatient.riskLevel} Risk
                      </Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      <div>
                        <span className="font-medium">Weeks:</span> {selectedPatient.pregnancyWeeks}
                      </div>
                      <div>
                        <span className="font-medium">Trimester:</span> {selectedPatient.trimester}
                      </div>
                      <div>
                        <span className="font-medium">Due Date:</span>{" "}
                        {new Date(selectedPatient.dueDate).toLocaleDateString()}
                      </div>
                      <div>
                        <span className="font-medium">Current Weight:</span> {selectedPatient.currentWeight}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Health Metrics */}
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Current Health Metrics</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div className="text-center p-3 border rounded">
                      <div className="font-medium">Blood Pressure</div>
                      <div className="text-lg font-bold">{selectedPatient.bloodPressure}</div>
                    </div>
                    <div className="text-center p-3 border rounded">
                      <div className="font-medium">Heart Rate</div>
                      <div className="text-lg font-bold">{selectedPatient.heartRate} bpm</div>
                    </div>
                    <div className="text-center p-3 border rounded">
                      <div className="font-medium">Hemoglobin</div>
                      <div className="text-lg font-bold">{selectedPatient.labResults.hemoglobin}</div>
                    </div>
                    <div className="text-center p-3 border rounded">
                      <div className="font-medium">Glucose</div>
                      <div className="text-lg font-bold">{selectedPatient.labResults.glucose}</div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Medical History and Medications */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Card>
                  <CardHeader>
                    <CardTitle className="text-base">Medical History</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <ul className="space-y-1 text-sm">
                      {selectedPatient.medicalHistory.map((item, index) => (
                        <li key={index} className="flex items-start gap-2">
                          <div className="h-1.5 w-1.5 rounded-full bg-blue-500 mt-2 flex-shrink-0" />
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle className="text-base">Current Medications</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <ul className="space-y-2 text-sm">
                      {selectedPatient.currentMedications.map((medication, index) => (
                        <li key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                          <span>{medication}</span>
                          <Badge variant="outline" className="text-xs">
                            Active
                          </Badge>
                        </li>
                      ))}
                    </ul>
                  </CardContent>
                </Card>
              </div>

              {/* Emergency Contact */}
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Emergency Contact & Insurance</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div>
                      <p>
                        <span className="font-medium">Emergency Contact:</span> {selectedPatient.emergencyContact}
                      </p>
                      <p>
                        <span className="font-medium">Emergency Phone:</span> {selectedPatient.emergencyPhone}
                      </p>
                    </div>
                    <div>
                      <p>
                        <span className="font-medium">Insurance:</span> {selectedPatient.insurance}
                      </p>
                      <p>
                        <span className="font-medium">Marital Status:</span> {selectedPatient.maritalStatus}
                      </p>
                      <p>
                        <span className="font-medium">Occupation:</span> {selectedPatient.occupation}
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
