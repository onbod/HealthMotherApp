"use client"

import { useState, useMemo, useEffect } from "react"
import {
  Search,
  Users,
  Heart,
  AlertTriangle,
  Baby,
  Eye,
  Phone,
  Mail,
  X,
  ChevronDown,
  SlidersHorizontal,
} from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { Checkbox } from "@/components/ui/checkbox"
import { Slider } from "@/components/ui/slider"
import { useIsMobile } from "@/hooks/use-mobile"
import { useRouter } from "next/navigation"
import { PatientDetail } from "@/components/patient-detail"
import { toFhirPatient, toFhirEncounter } from "../lib/fhir-resources"

interface PatientProfilesProps {
  onSelectPatient: (patientId: string) => void
  setFilteredPatientCount?: (count: number) => void
}

interface FilterState {
  trimester: string
  visitCountOperator: string
  visitCountValue: number
  riskLevel: string[]
  status: string[]
  ageRange: [number, number]
  dueWithinDays: number | null
}

// 1. Gestational age schedule for 8 contacts
const contactSchedule = [
  { contact: 1, ga: 12, label: "≤ 12 weeks" },
  { contact: 2, ga: 16, label: "13–16 weeks" },
  { contact: 3, ga: 20, label: "20 weeks" },
  { contact: 4, ga: 26, label: "26 weeks" },
  { contact: 5, ga: 30, label: "30 weeks" },
  { contact: 6, ga: 34, label: "34 weeks" },
  { contact: 7, ga: 36, label: "36 weeks" },
  { contact: 8, ga: 38, label: "38–40 weeks" },
]

// Helper to get latest visit info (GA and date)
function getLatestVisitInfo(data: any) {
  let latestVisitNum = 0;
  let latestDate = null;
  let latestGA = null;
  for (let i = 1; i <= 8; i++) {
    const visit = data[`visit${i}`];
    if (visit && visit.presentPregnancy && visit.presentPregnancy.dateOfANCContact) {
      const visitDate = visit.presentPregnancy.dateOfANCContact.toDate ? visit.presentPregnancy.dateOfANCContact.toDate() : new Date(visit.presentPregnancy.dateOfANCContact);
      if (!latestDate || visitDate > latestDate) {
        latestDate = visitDate;
        latestGA = Number(visit.presentPregnancy.gestationalAge);
        latestVisitNum = i;
      }
    }
  }
  return { latestVisitNum, latestDate, latestGA };
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

// Refined next appointment calculation
function calculateNextAppointmentFromData(data: any) {
  const { latestVisitNum, latestDate, latestGA } = getLatestVisitInfo(data);
  if (!latestVisitNum || !latestDate || latestGA == null) return null;
  if (latestVisitNum >= contactSchedule.length) return null;
  const nextContact = contactSchedule[latestVisitNum]; // next contact is index = latestVisitNum
  if (!nextContact) return null;
  const weeksToAdd = nextContact.ga - latestGA;
  const nextDate = new Date(latestDate.getTime() + weeksToAdd * 7 * 24 * 60 * 60 * 1000);
  return { date: nextDate, label: nextContact.label, contact: nextContact.contact };
}

const calculateAge = (birthDate: string) => {
  if (!birthDate) return 0;
  const birth = new Date(birthDate);
  const today = new Date();
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age;
};

const getTrimester = (weeks: number) => {
  if (weeks < 13) return "1st";
  if (weeks < 27) return "2nd";
  if (weeks < 41) return "3rd";
  return "Postpartum";
};

const defaultAppointments = 8;
const todayStr = new Date().toISOString();

export function PatientProfiles({ onSelectPatient, setFilteredPatientCount }: PatientProfilesProps) {
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedPatient, setSelectedPatient] = useState<(typeof patients)[0] | null>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isFilterOpen, setIsFilterOpen] = useState(false)
  const [sortBy, setSortBy] = useState("name")
  const [sortOrder, setSortOrder] = useState("asc")
  const isMobile = useIsMobile()
  const [patients, setPatients] = useState([
    {
      id: "1",
      clientNumber: "001",
      clientName: "Marie Kamara",
      name: "Marie Kamara",
      gender: "female",
      birthDate: "1990-02-15",
      age: calculateAge("1990-02-15"),
      phoneNumber: "1234567890",
      phone: "1234567890",
      email: "marie.kamara@example.com",
      address: "123 Main St",
      emergencyContact: "Jane Doe",
      emergencyPhone: "555-1234",
      riskLevel: "Medium",
      status: "Active",
      weeks: 36,
      trimester: getTrimester(36),
      dueDate: "2024-02-15",
      visitCount: 6,
      totalAppointments: defaultAppointments,
      lastVisit: todayStr,
      nextAppointment: todayStr,
      nextAppointmentLabel: "38–40 weeks",
      bloodType: "O+"
    },
    {
      id: "2",
      clientNumber: "002",
      clientName: "Emmanuella Turay",
      name: "Emmanuella Turay",
      gender: "female",
      birthDate: "1992-03-20",
      age: calculateAge("1992-03-20"),
      phoneNumber: "2345678901",
      phone: "2345678901",
      email: "emmanuella.turay@example.com",
      address: "456 Elm St",
      emergencyContact: "John Doe",
      emergencyPhone: "555-2345",
      riskLevel: "Low",
      status: "Active",
      weeks: 24,
      trimester: getTrimester(24),
      dueDate: "2024-03-20",
      visitCount: 4,
      totalAppointments: defaultAppointments,
      lastVisit: todayStr,
      nextAppointment: todayStr,
      nextAppointmentLabel: "26 weeks",
      bloodType: "A+"
    },
    {
      id: "3",
      clientNumber: "003",
      clientName: "Sarah Conteh",
      name: "Sarah Conteh",
      gender: "female",
      birthDate: "1995-04-10",
      age: calculateAge("1995-04-10"),
      phoneNumber: "3456789012",
      phone: "3456789012",
      email: "sarah.conteh@example.com",
      address: "789 Oak St",
      emergencyContact: "Mary Smith",
      emergencyPhone: "555-3456",
      riskLevel: "Low",
      status: "Active",
      weeks: 12,
      trimester: getTrimester(12),
      dueDate: "2024-04-10",
      visitCount: 2,
      totalAppointments: defaultAppointments,
      lastVisit: todayStr,
      nextAppointment: todayStr,
      nextAppointmentLabel: "13–16 weeks",
      bloodType: "B+"
    },
    {
      id: "4",
      clientNumber: "004",
      clientName: "Clara Deen",
      name: "Clara Deen",
      gender: "female",
      birthDate: "1998-04-25",
      age: calculateAge("1998-04-25"),
      phoneNumber: "4567890123",
      phone: "4567890123",
      email: "clara.deen@example.com",
      address: "321 Pine St",
      emergencyContact: "Paul Jones",
      emergencyPhone: "555-4567",
      riskLevel: "Low",
      status: "Active",
      weeks: 8,
      trimester: getTrimester(8),
      dueDate: "2024-04-25",
      visitCount: 1,
      totalAppointments: defaultAppointments,
      lastVisit: todayStr,
      nextAppointment: todayStr,
      nextAppointmentLabel: "13–16 weeks",
      bloodType: "AB+"
    }
  ])
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const [newPatient, setNewPatient] = useState({
    clientNumber: "",
    clientName: "",
    gender: "female",
    birthDate: "",
    phoneNumber: "",
    address: "",
    emergencyContact: "",
    dueDate: "",
    email: "",
    emergencyPhone: ""
  })
  const [adding, setAdding] = useState(false)
  const [addError, setAddError] = useState("")
  const [dateDisplays, setDateDisplays] = useState<{[id: string]: {dueDate: string, lastVisit: string, nextAppointment: string}}>({})

  // Filter state
  const [filters, setFilters] = useState<FilterState>({
    trimester: "",
    visitCountOperator: "gte",
    visitCountValue: 0,
    riskLevel: [],
    status: [],
    ageRange: [18, 45],
    dueWithinDays: null,
  })

  // Filter options
  const trimesterOptions = ["All", "1st", "2nd", "3rd", "Postpartum"]
  const riskLevelOptions = ["Low", "Medium", "High"]
  const statusOptions = ["Active", "Postpartum"]
  const visitCountOperators = [
    { value: "lt", label: "Less than" },
    { value: "eq", label: "Equal to" },
    { value: "gte", label: "Greater than or equal" },
    { value: "gt", label: "Greater than" },
  ]

  // Remove useEffect that fetches from Firestore

  // Calculate statistics with current filters
  const filteredPatients = useMemo(() => {
    const filtered = patients.filter((patient) => {
      // Search filter
      const lowerSearch = searchTerm.toLowerCase();
      const matchesSearch =
        (patient.name?.toLowerCase?.() || "").includes(lowerSearch) ||
        (patient.clientName?.toLowerCase?.() || "").includes(lowerSearch) ||
        (patient.email?.toLowerCase?.() || "").includes(lowerSearch) ||
        (patient.phone || "").toLowerCase().includes(lowerSearch) ||
        (patient.phoneNumber || "").toLowerCase().includes(lowerSearch) ||
        (patient.address?.toLowerCase?.() || "").includes(lowerSearch) ||
        (patient.riskLevel?.toLowerCase?.() || "").includes(lowerSearch);

      // Trimester filter
      const matchesTrimester =
        filters.trimester === "" || filters.trimester === "All" || patient.trimester === filters.trimester

      // Visit count filter
      let matchesVisitCount = true
      if (filters.visitCountValue > 0) {
        switch (filters.visitCountOperator) {
          case "lt":
            matchesVisitCount = (patient.visitCount ?? 0) < filters.visitCountValue
            break
          case "eq":
            matchesVisitCount = (patient.visitCount ?? 0) === filters.visitCountValue
            break
          case "gte":
            matchesVisitCount = (patient.visitCount ?? 0) >= filters.visitCountValue
            break
          case "gt":
            matchesVisitCount = (patient.visitCount ?? 0) > filters.visitCountValue
            break
        }
      }

      // Risk level filter
      const matchesRiskLevel = filters.riskLevel.length === 0 || filters.riskLevel.includes(patient.riskLevel || "")

      // Status filter
      const matchesStatus = filters.status.length === 0 || filters.status.includes(patient.status || "")

      // Age range filter
      const matchesAge = (patient.age ?? 0) >= filters.ageRange[0] && (patient.age ?? 0) <= filters.ageRange[1]

      // Due within days filter
      let matchesDueDate = true
      if (filters.dueWithinDays !== null && patient.status === "Active") {
        const dueDate = new Date(patient.dueDate || "")
        const today = new Date()
        const diffTime = dueDate.getTime() - today.getTime()
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
        matchesDueDate = diffDays <= filters.dueWithinDays && diffDays > 0
      }

      return (
        matchesSearch &&
        matchesTrimester &&
        matchesVisitCount &&
        matchesRiskLevel &&
        matchesStatus &&
        matchesAge &&
        matchesDueDate
      )
    })

    // Sort patients
    filtered.sort((a, b) => {
      let aValue: any = a[sortBy as keyof typeof a]
      let bValue: any = b[sortBy as keyof typeof b]

      if (sortBy === "name") {
        aValue = (a.name?.toLowerCase?.() || "")
        bValue = (b.name?.toLowerCase?.() || "")
      } else if (sortBy === "age" || sortBy === "visitCount" || sortBy === "pregnancyWeeks") {
        aValue = Number(aValue ?? 0)
        bValue = Number(bValue ?? 0)
      } else if (sortBy === "lastVisit" || sortBy === "dueDate") {
        aValue = new Date(aValue || "1970-01-01")
        bValue = new Date(bValue || "1970-01-01")
      }

      if (sortOrder === "asc") {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0
      }
    })

    return filtered
  }, [searchTerm, filters, sortBy, sortOrder, patients])

  const totalPatients = patients.length
  const activePatients = filteredPatients.filter((p) => p.status === "Active").length
  const postpartumPatients = filteredPatients.filter((p) => p.status === "Postpartum").length
  const highRiskPatients = filteredPatients.filter((p) => p.riskLevel === "High").length
  const dueSoon = filteredPatients.filter((p) => {
    if (p.status === "Postpartum") return false
    const dueDate = new Date(p.dueDate)
    const today = new Date()
    const diffTime = dueDate.getTime() - today.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    return diffDays <= 30 && diffDays > 0
  }).length

  const handleFilterChange = (key: keyof FilterState, value: any) => {
    setFilters((prev) => ({ ...prev, [key]: value }))
  }

  const handleMultiSelectFilter = (key: keyof FilterState, value: string) => {
    setFilters((prev) => {
      const currentValues = prev[key] as string[]
      const newValues = currentValues.includes(value)
        ? currentValues.filter((v) => v !== value)
        : [...currentValues, value]
      return { ...prev, [key]: newValues }
    })
  }

  const clearAllFilters = () => {
    setFilters({
      trimester: "",
      visitCountOperator: "gte",
      visitCountValue: 0,
      riskLevel: [],
      status: [],
      ageRange: [18, 45],
      dueWithinDays: null,
    })
    setSearchTerm("")
  }

  const getActiveFilterCount = () => {
    let count = 0
    if (filters.trimester && filters.trimester !== "All") count++
    if (filters.visitCountValue > 0) count++
    if (filters.riskLevel.length > 0) count++
    if (filters.status.length > 0) count++
    if (filters.ageRange[0] !== 18 || filters.ageRange[1] !== 45) count++
    if (filters.dueWithinDays !== null) count++
    if (searchTerm) count++
    return count
  }

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case "High":
        return "destructive";
      case "Medium":
        return "warning";
      case "Low":
      case "":
      default:
        return "success";
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

  const handleRowClick = (patient: (typeof patients)[0]) => {
    setSelectedPatient(patient)
    setIsModalOpen(true)
  }

  const handleViewMore = () => {
    if (selectedPatient) {
      setIsModalOpen(false);
      onSelectPatient(selectedPatient.id);
    }
  }

  const calculateWeeksRemaining = (dueDate: string) => {
    const due = new Date(dueDate)
    const today = new Date()
    const diffTime = due.getTime() - today.getTime()
    const diffWeeks = Math.ceil(diffTime / (1000 * 60 * 60 * 24 * 7))
    return diffWeeks > 0 ? diffWeeks : 0
  }

  // Mobile Card View Component
  const MobilePatientCard = ({ patient }: { patient: (typeof patients)[0] }) => (
    <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => handleRowClick(patient)}>
      <CardContent className="p-4">
        <div className="flex items-start space-x-3">
          <Avatar className="h-12 w-12">
            <AvatarImage src={`/placeholder.svg?height=48&width=48`} />
            <AvatarFallback>
              {getInitials(patient.clientName || patient.name || "")}
            </AvatarFallback>
          </Avatar>
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="font-semibold text-base truncate">{patient.clientName || patient.name}</h3>
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

            <div className="mt-3 space-y-2">
              <div className="flex items-center gap-2 text-sm">
                <Phone className="h-3 w-3 text-muted-foreground" />
                <span className="truncate">{patient.phone}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Mail className="h-3 w-3 text-muted-foreground" />
                <span className="truncate">{patient.email}</span>
              </div>
            </div>

            {patient.status === "Active" && (
              <div className="mt-3 p-2 bg-blue-50 rounded-lg">
                <div className="text-sm">
                  <span className="font-medium">{patient.weeks}</span>
                  <span className="text-muted-foreground"> ({patient.trimester})</span>
                </div>
                <div className="text-xs text-muted-foreground">
                  Due: {dateDisplays[patient.id]?.dueDate}
                </div>
              </div>
            )}

            <div className="mt-3 flex justify-between items-center text-xs text-muted-foreground">
              <span>
                Visits: {patient.visitCount}/{patient.totalAppointments}
              </span>
              <span>Last: {dateDisplays[patient.id]?.lastVisit}</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )

  useEffect(() => {
    if (setFilteredPatientCount) {
      setFilteredPatientCount(filteredPatients.length)
    }
  }, [filteredPatients, setFilteredPatientCount])

  useEffect(() => {
    // After hydration, format all patient dates for display
    const displays: {[id: string]: {dueDate: string, lastVisit: string, nextAppointment: string}} = {}
    patients.forEach(p => {
      displays[p.id] = {
        dueDate: p.dueDate ? new Date(p.dueDate).toLocaleDateString() : '',
        lastVisit: p.lastVisit ? new Date(p.lastVisit).toLocaleDateString() : '',
        nextAppointment: p.nextAppointment ? new Date(p.nextAppointment).toLocaleDateString() : ''
      }
    })
    setDateDisplays(displays)
  }, [patients])

  // Add New Patient Handler
  const handleAddPatient = async (e: React.FormEvent) => {
    e.preventDefault()
    setAdding(true)
    setAddError("")
    try {
      if (!newPatient.clientNumber || !newPatient.clientName || !newPatient.birthDate) {
        setAddError("Client number, name, and birth date are required.")
        setAdding(false)
        return
      }
      const age = calculateAge(newPatient.birthDate)
      const weeks = 0
      const trimester = getTrimester(weeks)
      setPatients(prev => [
        {
          id: (prev.length + 1).toString(),
          ...newPatient,
          name: newPatient.clientName,
          age,
          phone: newPatient.phoneNumber,
          email: newPatient.email || "new.patient@example.com",
          riskLevel: "Low",
          status: "Active",
          weeks,
          trimester,
          dueDate: newPatient.dueDate || "",
          visitCount: 0,
          totalAppointments: defaultAppointments,
          lastVisit: todayStr,
          nextAppointment: todayStr,
          nextAppointmentLabel: "13–16 weeks",
          bloodType: "O+",
          emergencyPhone: newPatient.emergencyPhone || "555-0000"
        },
        ...prev
      ])
      setIsAddModalOpen(false)
      setNewPatient({
        clientNumber: "",
        clientName: "",
        gender: "female",
        birthDate: "",
        phoneNumber: "",
        address: "",
        emergencyContact: "",
        dueDate: "",
        email: "",
        emergencyPhone: ""
      })
    } finally {
      setAdding(false)
    }
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold">Patient Profiles</h1>
          <p className="text-muted-foreground text-sm sm:text-base">
            Manage maternal health records and patient information
          </p>
        </div>
        <Button className="w-full sm:w-auto" onClick={() => setIsAddModalOpen(true)}>Add New Patient</Button>
      </div>
      {/* Add Patient Modal */}
      <Dialog open={isAddModalOpen} onOpenChange={setIsAddModalOpen}>
        <DialogContent className="max-w-md w-full">
          <DialogHeader>
            <DialogTitle>Add New Patient</DialogTitle>
          </DialogHeader>
          <form className="space-y-4" onSubmit={handleAddPatient}>
            <div>
              <label className="block text-sm font-medium mb-1">Client Number *</label>
              <Input value={newPatient.clientNumber} onChange={e => setNewPatient(p => ({ ...p, clientNumber: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Full Name *</label>
              <Input value={newPatient.clientName} onChange={e => setNewPatient(p => ({ ...p, clientName: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Gender</label>
              <Select value={newPatient.gender} onValueChange={val => setNewPatient(p => ({ ...p, gender: val }))}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="female">Female</SelectItem>
                  <SelectItem value="male">Male</SelectItem>
                  <SelectItem value="other">Other</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Birth Date *</label>
              <Input type="date" value={newPatient.birthDate} onChange={e => setNewPatient(p => ({ ...p, birthDate: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Phone</label>
              <Input value={newPatient.phoneNumber} onChange={e => setNewPatient(p => ({ ...p, phoneNumber: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Address</label>
              <Input value={newPatient.address} onChange={e => setNewPatient(p => ({ ...p, address: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Emergency Contact</label>
              <Input value={newPatient.emergencyContact} onChange={e => setNewPatient(p => ({ ...p, emergencyContact: e.target.value }))} />
            </div>
            {addError && <div className="text-red-600 text-sm">{addError}</div>}
            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setIsAddModalOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={adding}>{adding ? "Adding..." : "Add Patient"}</Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Statistics Cards */}
      <div className="grid gap-3 sm:gap-4 grid-cols-2 lg:grid-cols-4">
        <Card className="bg-gradient-to-br from-green-600 to-green-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Active Users</CardTitle>
            <Users className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{filteredPatients.length}</div>
            <p className="text-xs text-muted-foreground-black">of total Users</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-blue-600 to-blue-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium text-white">Active Pregnancies</CardTitle>
            <Heart className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{activePatients}</div>
            <p className="text-xs text-muted-foreground-black">Currently under prenatal care</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-red-600 to-red-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">High Risk Patients</CardTitle>
            <AlertTriangle className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{highRiskPatients}</div>
            <p className="text-xs text-muted-foreground-white">Requiring special attention</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-yellow-600 to-yellow-700 text-white">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Due Soon</CardTitle>
            <Baby className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground-white" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{dueSoon}</div>
            <p className="text-xs text-muted-foreground-white">Due within 30 days</p>
          </CardContent>
        </Card>
      </div>

      {/* Search, Filter, and Sort Controls */}
      <div className="flex flex-col gap-4">
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center space-y-2 sm:space-y-0 sm:space-x-4">
          <div className="relative flex-1 max-w-full sm:max-w-sm">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search patients..."
              className="pl-10"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          {/* Trimester Dropdown Filter */}
          <Select value={filters.trimester} onValueChange={(value) => handleFilterChange("trimester", value)}>
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="Filter by trimester" />
            </SelectTrigger>
            <SelectContent>
              {trimesterOptions.map((option) => (
                <SelectItem key={option} value={option}>
                  {option === "All" ? "All Trimesters" : `${option}${option !== "Postpartum" ? " Trimester" : ""}`}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          <div className="flex gap-2">
            <Button variant="outline" onClick={() => setIsFilterOpen(true)} className="flex items-center gap-2">
              <SlidersHorizontal className="h-4 w-4" />
              More Filters
              {getActiveFilterCount() > 0 && (
                <Badge variant="secondary" className="ml-1">
                  {getActiveFilterCount()}
                </Badge>
              )}
            </Button>

            <Select value={sortBy} onValueChange={setSortBy}>
              <SelectTrigger className="w-[140px]">
                <SelectValue placeholder="Sort by" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="name">Name</SelectItem>
                <SelectItem value="age">Age</SelectItem>
                <SelectItem value="pregnancyWeeks">Pregnancy Weeks</SelectItem>
                <SelectItem value="visitCount">Visit Count</SelectItem>
                <SelectItem value="lastVisit">Last Visit</SelectItem>
                <SelectItem value="dueDate">Due Date</SelectItem>
              </SelectContent>
            </Select>

            <Button variant="outline" size="icon" onClick={() => setSortOrder(sortOrder === "asc" ? "desc" : "asc")}> 
              <ChevronDown className={`h-4 w-4 transition-transform ${sortOrder === "desc" ? "rotate-180" : ""}`} />
            </Button>
          </div>
        </div>

        {/* Active Filters Display */}
        {getActiveFilterCount() > 0 && (
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm text-muted-foreground">Active filters:</span>
            {searchTerm && (
              <Badge variant="secondary" className="flex items-center gap-1">
                Search: "{searchTerm}"
                <X className="h-3 w-3 cursor-pointer" onClick={() => setSearchTerm("")} />
              </Badge>
            )}
            {filters.trimester && filters.trimester !== "All" && (
              <Badge variant="secondary" className="flex items-center gap-1">
                {filters.trimester} Trimester
                <X className="h-3 w-3 cursor-pointer" onClick={() => handleFilterChange("trimester", "")} />
              </Badge>
            )}
            {filters.visitCountValue > 0 && (
              <Badge variant="secondary" className="flex items-center gap-1">
                Visits {visitCountOperators.find((op) => op.value === filters.visitCountOperator)?.label.toLowerCase()}{" "}
                {filters.visitCountValue}
                <X className="h-3 w-3 cursor-pointer" onClick={() => handleFilterChange("visitCountValue", 0)} />
              </Badge>
            )}
            {filters.riskLevel.map((risk) => (
              <Badge key={risk} variant="secondary" className="flex items-center gap-1">
                {risk} Risk
                <X className="h-3 w-3 cursor-pointer" onClick={() => handleMultiSelectFilter("riskLevel", risk)} />
              </Badge>
            ))}
            {filters.status.map((status) => (
              <Badge key={status} variant="secondary" className="flex items-center gap-1">
                {status}
                <X className="h-3 w-3 cursor-pointer" onClick={() => handleMultiSelectFilter("status", status)} />
              </Badge>
            ))}
            {(filters.ageRange[0] !== 18 || filters.ageRange[1] !== 45) && (
              <Badge variant="secondary" className="flex items-center gap-1">
                Age: {filters.ageRange[0]}-{filters.ageRange[1]}
                <X className="h-3 w-3 cursor-pointer" onClick={() => handleFilterChange("ageRange", [18, 45])} />
              </Badge>
            )}
            {filters.dueWithinDays !== null && (
              <Badge variant="secondary" className="flex items-center gap-1">
                Due within {filters.dueWithinDays} days
                <X className="h-3 w-3 cursor-pointer" onClick={() => handleFilterChange("dueWithinDays", null)} />
              </Badge>
            )}
            <Button variant="ghost" size="sm" onClick={clearAllFilters} className="text-xs">
              Clear all
            </Button>
          </div>
        )}
      </div>

      {/* Patient List */}
      {isMobile ? (
        <div className="space-y-3">
          <div className="text-sm text-muted-foreground">
            Showing {filteredPatients.length} of {totalPatients} patients
          </div>
          <div className="space-y-3">
            {filteredPatients.map((patient) => (
              <MobilePatientCard key={patient.id} patient={patient} />
            ))}
          </div>
        </div>
      ) : (
        /* Desktop Table View */
        <Card>
          <CardHeader>
            <CardTitle>Patient List</CardTitle>
            <CardDescription>
              Click on any row to view patient summary. Showing {filteredPatients.length} of {totalPatients} patients.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="min-w-[200px]">Patient</TableHead>
                    <TableHead>Age</TableHead>
                    <TableHead className="min-w-[140px]">Contact</TableHead>
                    <TableHead className="min-w-[150px]">Pregnancy Status</TableHead>
                    <TableHead className="min-w-[120px]">Due Date</TableHead>
                    <TableHead>Risk Level</TableHead>
                    <TableHead>Visits</TableHead>
                    <TableHead>Last Visit</TableHead>
                    <TableHead>Next Appointment</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredPatients.map((patient) => (
                    <TableRow
                      key={patient.id}
                      className="cursor-pointer hover:bg-muted/50 transition-colors"
                      onClick={() => handleRowClick(patient)}
                    >
                      <TableCell>
                        <div className="flex items-center space-x-3">
                          <Avatar className="h-8 w-8">
                            <AvatarImage src={`/placeholder.svg?height=32&width=32`} />
                            <AvatarFallback className="text-xs">
                              {getInitials(patient.clientName || patient.name || "")}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <div className="font-medium">{patient.clientName || patient.name}</div>
                            <div className="text-sm text-muted-foreground">{patient.email}</div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{patient.age}</TableCell>
                      <TableCell>
                        <div className="text-sm">
                          <div>{patient.phone}</div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center space-x-2">
                          <Badge variant={getStatusColor(patient.status) as any}>{patient.status}</Badge>
                          {patient.status === "Active" && (
                            <span className="text-sm text-muted-foreground">
                              {patient.weeks} ({patient.trimester})
                            </span>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="text-sm">
                          <div>{dateDisplays[patient.id]?.dueDate}</div>
                          {patient.status === "Active" && (
                            <div className="text-muted-foreground">
                              {calculateWeeksRemaining(patient.dueDate)} weeks left
                            </div>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getRiskColor(patient.riskLevel) as any}>{patient.riskLevel || 'No Risk'}</Badge>
                      </TableCell>
                      <TableCell>
                        <div className="text-sm">
                          <div className="font-medium">
                            {patient.visitCount}/{patient.totalAppointments}
                          </div>
                          <div className="text-muted-foreground">
                            {Math.round((patient.visitCount / 8) * 100)}% complete
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className="text-sm">{dateDisplays[patient.id]?.lastVisit}</TableCell>
                      <TableCell className="text-sm">
                        {patient.nextAppointment
                          ? `${dateDisplays[patient.id]?.nextAppointment} (${patient.nextAppointmentLabel})`
                          : "All contacts complete"}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* No Results Message */}
      {filteredPatients.length === 0 && (
        <Card>
          <CardContent className="text-center py-12">
            <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-medium mb-2">No patients found</h3>
            <p className="text-muted-foreground mb-4">
              Try adjusting your search criteria or filters to find patients.
            </p>
            <Button variant="outline" onClick={clearAllFilters}>
              Clear all
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Advanced Filter Dialog */}
      <Dialog open={isFilterOpen} onOpenChange={setIsFilterOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Advanced Filters</DialogTitle>
          </DialogHeader>
          <div className="space-y-6">
            {/* Trimester Filter */}
            <div className="space-y-3">
              <Label className="text-base font-medium">Trimester</Label>
              <div className="grid grid-cols-2 gap-3">
                {trimesterOptions.map((trimester) => (
                  <div key={trimester} className="flex items-center space-x-2">
                    <input
                      type="radio"
                      id={`trimester-${trimester}`}
                      name="trimester"
                      checked={filters.trimester === trimester}
                      onChange={() => handleFilterChange("trimester", trimester)}
                      className="h-4 w-4 text-primary border-gray-300 focus:ring-primary"
                    />
                    <Label htmlFor={`trimester-${trimester}`} className="cursor-pointer">
                      {trimester === "All"
                        ? "All Trimesters"
                        : `${trimester}${trimester !== "Postpartum" ? " Trimester" : ""}`}
                    </Label>
                  </div>
                ))}
              </div>
            </div>

            <Separator />

            {/* Visit Count Filter */}
            <div className="space-y-3">
              <Label className="text-base font-medium">Number of Visits</Label>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <Label htmlFor="visit-operator" className="text-sm">
                    Condition
                  </Label>
                  <Select
                    value={filters.visitCountOperator}
                    onValueChange={(value) => handleFilterChange("visitCountOperator", value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {visitCountOperators.map((op) => (
                        <SelectItem key={op.value} value={op.value}>
                          {op.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label htmlFor="visit-count" className="text-sm">
                    Number of visits
                  </Label>
                  <Input
                    id="visit-count"
                    type="number"
                    min="0"
                    max="50"
                    value={filters.visitCountValue}
                    onChange={(e) => handleFilterChange("visitCountValue", Number.parseInt(e.target.value) || 0)}
                  />
                </div>
              </div>
            </div>

            <Separator />

            {/* Risk Level Filter */}
            <div className="space-y-3">
              <Label className="text-base font-medium">Risk Level</Label>
              <div className="grid grid-cols-3 gap-3">
                {riskLevelOptions.map((risk) => (
                  <div key={risk} className="flex items-center space-x-2">
                    <Checkbox
                      id={`risk-${risk}`}
                      checked={filters.riskLevel.includes(risk)}
                      onCheckedChange={() => handleMultiSelectFilter("riskLevel", risk)}
                    />
                    <Label htmlFor={`risk-${risk}`} className="cursor-pointer">
                      {risk}
                    </Label>
                  </div>
                ))}
              </div>
            </div>

            <Separator />

            {/* Status Filter */}
            <div className="space-y-3">
              <Label className="text-base font-medium">Patient Status</Label>
              <div className="grid grid-cols-2 gap-3">
                {statusOptions.map((status) => (
                  <div key={status} className="flex items-center space-x-2">
                    <Checkbox
                      id={`status-${status}`}
                      checked={filters.status.includes(status)}
                      onCheckedChange={() => handleMultiSelectFilter("status", status)}
                    />
                    <Label htmlFor={`status-${status}`} className="cursor-pointer">
                      {status}
                    </Label>
                  </div>
                ))}
              </div>
            </div>

            <Separator />

            {/* Age Range Filter */}
            <div className="space-y-3">
              <Label className="text-base font-medium">Age Range</Label>
              <div className="space-y-2">
                <div className="flex justify-between text-sm text-muted-foreground">
                  <span>{filters.ageRange[0]} years</span>
                  <span>{filters.ageRange[1]} years</span>
                </div>
                <Slider
                  value={filters.ageRange}
                  onValueChange={(value) => handleFilterChange("ageRange", value)}
                  min={18}
                  max={45}
                  step={1}
                  className="w-full"
                />
              </div>
            </div>

            <Separator />

            {/* Due Within Days Filter */}
            <div className="space-y-3">
              <Label className="text-base font-medium">Due Within (Days)</Label>
              <div className="grid grid-cols-2 gap-3">
                <Button
                  variant={filters.dueWithinDays === null ? "default" : "outline"}
                  onClick={() => handleFilterChange("dueWithinDays", null)}
                  className="justify-start"
                >
                  Any time
                </Button>
                {[7, 14, 30, 60].map((days) => (
                  <Button
                    key={days}
                    variant={filters.dueWithinDays === days ? "default" : "outline"}
                    onClick={() => handleFilterChange("dueWithinDays", days)}
                    className="justify-start"
                  >
                    {days} days
                  </Button>
                ))}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-col sm:flex-row justify-end space-y-2 sm:space-y-0 sm:space-x-3 pt-4 border-t">
              <Button variant="outline" onClick={clearAllFilters} className="w-full sm:w-auto">
                Clear All Filters
              </Button>
              <Button onClick={() => setIsFilterOpen(false)} className="w-full sm:w-auto">
                Apply Filters
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Patient Summary Modal */}
      <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-3">
              <Avatar className="h-10 w-10">
                <AvatarImage src={`/placeholder.svg?height=40&width=40`} />
                <AvatarFallback>
                  {getInitials(selectedPatient?.clientName || selectedPatient?.name || "")}
                </AvatarFallback>
              </Avatar>
              <div>
                <div className="text-xl font-semibold">{selectedPatient?.name}</div>
                <div className="text-sm text-muted-foreground font-normal">Patient Summary</div>
              </div>
            </DialogTitle>
          </DialogHeader>

          {selectedPatient && (
            <div className="mb-4 p-4 bg-muted rounded-lg grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div><span className="font-medium">Name:</span> {selectedPatient.clientName || selectedPatient.name}</div>
              <div><span className="font-medium">Age:</span> {selectedPatient.age}</div>
              <div><span className="font-medium">Phone:</span> {selectedPatient.phoneNumber || selectedPatient.phone}</div>
              <div><span className="font-medium">Email:</span> {selectedPatient.email}</div>
              <div><span className="font-medium">Risk Level:</span> <Badge variant={getRiskColor(selectedPatient.riskLevel) as any}>{selectedPatient.riskLevel || 'No Risk'}</Badge></div>
              <div><span className="font-medium">Status:</span> <Badge variant={getStatusColor(selectedPatient.status) as any}>{selectedPatient.status}</Badge></div>
              <div><span className="font-medium">Gestational Age:</span> {selectedPatient.weeks} weeks</div>
              <div><span className="font-medium">Last Visit:</span> {dateDisplays[selectedPatient.id]?.lastVisit}</div>
              <div><span className="font-medium">Next Appointment:</span> {dateDisplays[selectedPatient.id]?.nextAppointment} ({selectedPatient.nextAppointmentLabel})</div>
            </div>
          )}

          {selectedPatient && (
            <div className="space-y-6">
              {/* Basic Information */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-3">
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">Personal Information</h4>
                    <div className="mt-1 space-y-1">
                      <p className="text-sm">
                        <span className="font-medium">Age:</span> {selectedPatient.age}
                      </p>
                      <p className="text-sm">
                        <span className="font-medium">Blood Type:</span> {selectedPatient.bloodType}
                      </p>
                      <p className="text-sm">
                        <span className="font-medium">Phone:</span> {selectedPatient.phone}
                      </p>
                      <p className="text-sm">
                        <span className="font-medium">Email:</span> {selectedPatient.email}
                      </p>
                    </div>
                  </div>
                </div>

                <div className="space-y-3">
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">Emergency Contact</h4>
                    <div className="mt-1 space-y-1">
                      <p className="text-sm">
                        <span className="font-medium">Contact:</span> {selectedPatient.emergencyContact}
                      </p>
                      <p className="text-sm">
                        <span className="font-medium">Phone:</span> {selectedPatient.emergencyPhone}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Pregnancy Information */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground mb-2">Pregnancy Status</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2">
                      <Badge variant={getStatusColor(selectedPatient.status) as any}>{selectedPatient.status}</Badge>
                      <Badge variant={getRiskColor(selectedPatient.riskLevel) as any}>
                        {selectedPatient.riskLevel} Risk
                      </Badge>
                    </div>
                    {selectedPatient.status === "Active" && (
                      <div className="text-sm space-y-1">
                        <p>
                          <span className="font-medium">Weeks:</span> {selectedPatient.weeks}
                        </p>
                        <p>
                          <span className="font-medium">Trimester:</span> {selectedPatient.trimester}
                        </p>
                      </div>
                    )}
                  </div>
                  <div className="text-sm space-y-1">
                    <p>
                      <span className="font-medium">Due Date:</span>{" "}
                      {dateDisplays[selectedPatient.id]?.dueDate}
                    </p>
                    {selectedPatient.status === "Active" && (
                      <p>
                        <span className="font-medium">Weeks Remaining:</span>{" "}
                        {calculateWeeksRemaining(selectedPatient.dueDate)}
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Visit Information */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground mb-2">Visit History</h4>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
                  <div>
                    <p>
                      <span className="font-medium">Total Visits:</span> {selectedPatient.visitCount}
                    </p>
                  </div>
                  <div>
                    <p>
                      <span className="font-medium">Scheduled:</span> {selectedPatient.totalAppointments}
                    </p>
                  </div>
                  <div>
                    <p>
                      <span className="font-medium">Completion Rate:</span>{" "}
                      {Math.round((selectedPatient.visitCount / selectedPatient.totalAppointments) * 100)}%
                    </p>
                  </div>
                </div>
              </div>

              {/* Appointment Information */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground mb-2">Appointments</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                  <div>
                    <p>
                      <span className="font-medium">Last Visit:</span>{" "}
                      {dateDisplays[selectedPatient.id]?.lastVisit}
                    </p>
                  </div>
                  <div>
                    <p>
                      <span className="font-medium">Next Appointment:</span>{" "}
                      {dateDisplays[selectedPatient.id]?.nextAppointment} ({selectedPatient.nextAppointmentLabel})
                    </p>
                  </div>
                </div>
              </div>

              {/* Address */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground mb-1">Address</h4>
                <p className="text-sm">{selectedPatient.address}</p>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col sm:flex-row justify-end space-y-2 sm:space-y-0 sm:space-x-3 pt-4 border-t">
                <Button variant="outline" onClick={() => setIsModalOpen(false)} className="w-full sm:w-auto">
                  Close
                </Button>
                <Button
                  onClick={handleViewMore}
                  className="flex items-center justify-center space-x-2 w-full sm:w-auto"
                >
                  <Eye className="h-4 w-4" />
                  <span>View More Details</span>
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
