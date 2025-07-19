"use client"

import { useState, useEffect } from "react"
import { 
  BookOpen, 
  Apple, 
  Heart, 
  Baby, 
  Send, 
  Users, 
  Filter, 
  Search,
  ChevronDown,
  CheckCircle,
  Clock,
  AlertCircle,
  Target,
  Calendar,
  TrendingUp,
  MessageSquare,
  Plus,
  Edit,
  Trash2,
  Eye,
  Download,
  Video
} from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Progress } from "@/components/ui/progress"
// Remove: import { collection, getDocs, doc, updateDoc, addDoc, serverTimestamp, deleteDoc } from "firebase/firestore"
// Remove: import { db } from "../lib/firebase"
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem
} from "@/components/ui/dropdown-menu"

interface HealthTip {
  id: string
  title: string
  content: string
  category: "health" | "nutrition" | "video"
  targetStage: "first-trimester" | "second-trimester" | "third-trimester" | "delivery"
  targetWeeks?: number[]
  targetVisits?: number[]
  createdAt: any
  sentCount: number
  isActive: boolean
  weeks?: string | number
  categoryType?: string
  nutritionType?: string
}

interface Patient {
  id: string
  name: string
  weeks: number
  trimester: string
  visitCount: number
  status: string
  hasDelivered: boolean
  email?: string
  phone?: string
}

export function HealthEducation() {
  const [activeTab, setActiveTab] = useState("health-tips")
  const [selectedCategory, setSelectedCategory] = useState<"health" | "nutrition">("health")
  const [patients, setPatients] = useState<Patient[]>([])
  const [filteredPatients, setFilteredPatients] = useState<Patient[]>([])
  const [healthTips, setHealthTips] = useState<HealthTip[]>([])
  const [selectedTip, setSelectedTip] = useState<HealthTip | null>(null)
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [isSendModalOpen, setIsSendModalOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState("")
  const [filterStage, setFilterStage] = useState<string>("all")
  const [loading, setLoading] = useState(true)

  // Form states
  const [tipTitle, setTipTitle] = useState("")
  const [tipContent, setTipContent] = useState("")
  const [tipCategory, setTipCategory] = useState<"health" | "nutrition">("health")
  const [tipTargetStage, setTipTargetStage] = useState<string>("first-trimester")
  const [tipTargetWeeks, setTipTargetWeeks] = useState<string>("")
  const [tipTargetVisits, setTipTargetVisits] = useState<string>("")
  const [createTipType, setCreateTipType] = useState<null | 'health' | 'nutrition' | 'video'>(null)
  const [tipWeeks, setTipWeeks] = useState<string>("")
  const [tipTrimester, setTipTrimester] = useState<string>("")
  const [tipVisit, setTipVisit] = useState<string>("")
  const [tipScheduleDate, setTipScheduleDate] = useState<string>("")

  const [healthTipsCount, setHealthTipsCount] = useState(0);
  const [nutritionTipsCount, setNutritionTipsCount] = useState(0);
  const [healthVideosCount, setHealthVideosCount] = useState(0);

  const [editTipId, setEditTipId] = useState<string | null>(null);
  const [categoryType, setCategoryType] = useState<string>("");
  const [nutritionType, setNutritionType] = useState<string>("");

  const currentUserId = "admin"; // Replace with actual user ID from auth

  useEffect(() => {
    fetchPatients()
    fetchHealthTips()
  }, [])

  useEffect(() => {
    if (!isCreateModalOpen) {
      setTipTitle("");
      setTipContent("");
      setTipCategory("health");
      setTipTargetStage("first-trimester");
      setTipTargetWeeks("");
      setTipTargetVisits("");
      setTipWeeks("");
      setTipTrimester("");
      setTipVisit("");
      setTipScheduleDate("");
      setCreateTipType(null);
      setCategoryType("");
      setNutritionType("");
    }
  }, [isCreateModalOpen]);

  const fetchPatients = async () => {
    try {
      // Simulate fetching patients from a local state or dummy data
      const dummyPatients: Patient[] = [
        { id: "1", name: "Patient A", weeks: 10, trimester: "1st Trimester", visitCount: 1, status: "Active", hasDelivered: false, email: "patienta@example.com", phone: "123-456-7890" },
        { id: "2", name: "Patient B", weeks: 20, trimester: "2nd Trimester", visitCount: 2, status: "Active", hasDelivered: false, email: "patientb@example.com", phone: "987-654-3210" },
        { id: "3", name: "Patient C", weeks: 30, trimester: "3rd Trimester", visitCount: 3, status: "Active", hasDelivered: false, email: "patientc@example.com", phone: "112-358-1321" },
        { id: "4", name: "Patient D", weeks: 35, trimester: "Delivery", visitCount: 4, status: "Active", hasDelivered: false, email: "patientd@example.com", phone: "456-789-0123" },
        { id: "5", name: "Patient E", weeks: 40, trimester: "Delivery", visitCount: 5, status: "Active", hasDelivered: false, email: "patiente@example.com", phone: "789-012-3456" },
      ];
      setPatients(dummyPatients);
      setFilteredPatients(dummyPatients);
    } catch (error) {
      console.error("Error fetching patients:", error)
    } finally {
      setLoading(false)
    }
  }

  const fetchHealthTips = async () => {
    try {
      // Simulate fetching tips from a local state or dummy data
      const dummyHealthTips: HealthTip[] = [
        { id: "1", title: "Health Tip 1", content: "This is a health tip content 1.", category: "health", targetStage: "first-trimester", targetWeeks: [5, 10], createdAt: new Date(), sentCount: 10, isActive: true, weeks: "5,10", categoryType: "General Health" },
        { id: "2", title: "Health Tip 2", content: "This is a health tip content 2.", category: "health", targetStage: "second-trimester", targetWeeks: [15, 20], createdAt: new Date(), sentCount: 20, isActive: true, weeks: "15,20", categoryType: "Physical Health" },
        { id: "3", title: "Health Tip 3", content: "This is a health tip content 3.", category: "health", targetStage: "third-trimester", targetWeeks: [25, 30], createdAt: new Date(), sentCount: 30, isActive: true, weeks: "25,30", categoryType: "Mental Health" },
        { id: "4", title: "Nutrition Tip 1", content: "This is a nutrition tip content 1.", category: "nutrition", targetStage: "first-trimester", targetWeeks: [5], createdAt: new Date(), sentCount: 10, isActive: true, weeks: "5", nutritionType: "Pregnancy Nutrition" },
        { id: "5", title: "Nutrition Tip 2", content: "This is a nutrition tip content 2.", category: "nutrition", targetStage: "second-trimester", targetWeeks: [15], createdAt: new Date(), sentCount: 20, isActive: true, weeks: "15", nutritionType: "Snacks" },
        { id: "6", title: "Health Video 1", content: "This is a health video content 1.", category: "video", targetStage: "first-trimester", targetWeeks: [5], createdAt: new Date(), sentCount: 10, isActive: true, weeks: "5" },
        { id: "7", title: "Health Video 2", content: "This is a health video content 2.", category: "video", targetStage: "second-trimester", targetWeeks: [15], createdAt: new Date(), sentCount: 20, isActive: true, weeks: "15" },
      ];
      setHealthTips(dummyHealthTips);
      setHealthTipsCount(dummyHealthTips.length);
      setNutritionTipsCount(dummyHealthTips.filter(t => t.category === "nutrition").length);
      setHealthVideosCount(dummyHealthTips.filter(t => t.category === "video").length);
    } catch (error) {
      alert("Error fetching tips: " + (error as any).message);
    }
  }

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

  const getStageColor = (stage: string) => {
    switch (stage) {
      case "first-trimester": return "bg-blue-100 text-blue-800"
      case "second-trimester": return "bg-green-100 text-green-800"
      case "third-trimester": return "bg-purple-100 text-purple-800"
      case "delivery": return "bg-orange-100 text-orange-800"
      default: return "bg-gray-100 text-gray-800"
    }
  }

  const getCategoryIcon = (category: string) => {
    return category === "health" ? Heart : Apple
  }

  const handleEditTip = (tip: HealthTip) => {
    setEditTipId(tip.id);
    setTipTitle(tip.title);
    setTipContent(tip.content);
    setTipWeeks(tip.weeks ? String(tip.weeks) : "any");
    setTipTrimester(tip.targetStage || "any");
    setTipVisit(tip.targetVisits && tip.targetVisits.length > 0 ? String(tip.targetVisits[0]) : "any");
    setTipScheduleDate("");
    setCreateTipType(tip.category);
    setCategoryType(tip.categoryType || "");
    setNutritionType(tip.nutritionType || "");
    setIsCreateModalOpen(true);
  };

  const handleCreateTip = async () => {
    // Always provide all required HealthTip fields
    const baseTip: HealthTip = {
      id: editTipId || Date.now().toString(),
      title: tipTitle,
      content: tipContent,
      category: (createTipType as "health" | "nutrition" | "video") || "health",
      targetStage: (tipTrimester as HealthTip["targetStage"]) || "first-trimester",
      targetWeeks: tipWeeks && tipWeeks !== "any" ? [Number(tipWeeks)] : [],
      targetVisits: tipVisit && tipVisit !== "any" ? [Number(tipVisit)] : [],
      createdAt: new Date(),
      sentCount: 0,
      isActive: true,
      weeks: tipWeeks || "",
      categoryType: createTipType === 'health' ? categoryType : undefined,
      nutritionType: createTipType === 'nutrition' ? nutritionType : undefined,
    };
    try {
      if (editTipId) {
        // Simulate update
        const updatedTips = healthTips.map(tip =>
          tip.id === editTipId ? { ...tip, ...baseTip } : tip
        );
        setHealthTips(updatedTips);
        alert("Tip updated!");
      } else {
        // Simulate add
        setHealthTips(prev => [...prev, baseTip]);
        alert("Tip created and saved to local state!");
      }
      setIsCreateModalOpen(false);
      setEditTipId(null);
      fetchHealthTips(); // Re-fetch to update counts
    } catch (error) {
      alert("Error saving tip: " + (error as any).message);
    }
  };

  const handleDeleteTip = async (tip: HealthTip) => {
    if (!window.confirm("Are you sure you want to delete this tip?")) return;
    let collectionName = "health-tips";
    if (tip.category === "nutrition") collectionName = "nutrition-tips";
    if (tip.category === "video") collectionName = "health-videos";
    try {
      // Simulate delete
      const updatedTips = healthTips.filter(t => t.id !== tip.id);
      setHealthTips(updatedTips);
      alert("Tip deleted!");
      fetchHealthTips(); // Re-fetch to update counts
    } catch (error) {
      alert("Error deleting tip: " + (error as any).message);
    }
  };

  const handleSendTip = async (tip: HealthTip) => {
    // Filter patients based on tip criteria
    const eligiblePatients = patients.filter(patient => {
      if (tip.targetStage === "delivery" && !patient.hasDelivered) return false
      if (tip.targetStage !== "delivery" && patient.hasDelivered) return false
      if (tip.targetWeeks && !tip.targetWeeks.includes(patient.weeks)) return false
      if (tip.targetVisits && !tip.targetVisits.includes(patient.visitCount)) return false
      return true
    })

    // In real app, send notifications to eligible patients
    console.log(`Sending tip "${tip.title}" to ${eligiblePatients.length} patients`)
    setIsSendModalOpen(false)
  }

  const filteredTips = healthTips.filter(tip => {
    if (filterStage !== "all" && tip.targetStage !== filterStage) return false
    if (searchTerm && !tip.title.toLowerCase().includes(searchTerm.toLowerCase())) return false
    return true
  })

  const tipStats = {
    healthTips: healthTips.length,
    nutritionTips: healthTips.filter(tip => tip.category === "nutrition").length,
    totalSent: healthTips.reduce((sum, tip) => sum + tip.sentCount, 0),
    eligiblePatients: patients.filter(p => !p.hasDelivered).length
  }

  if (loading) {
    return <div>Loading...</div>
  }

  return (
    <div className="flex-1 space-y-6 p-2 md:p-6 pt-4 md:pt-8 bg-gray-50 min-h-screen">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2 md:gap-0">
        <h2 className="text-2xl md:text-3xl font-bold tracking-tight text-maternal-blue-700">Health Education Hub</h2>
        <div className="flex items-center space-x-2">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button className="bg-maternal-green-500 hover:bg-maternal-green-600 text-white font-semibold shadow-md"><Plus className="mr-2 h-4 w-4" /> Create New Tip</Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="w-48">
              <DropdownMenuItem onClick={() => { setCreateTipType('health'); setIsCreateModalOpen(true); }} className="hover:bg-maternal-blue-100">
                <Heart className="mr-2 h-4 w-4 text-maternal-blue-500" /> Health Tips
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => { setCreateTipType('nutrition'); setIsCreateModalOpen(true); }} className="hover:bg-maternal-green-100">
                <Apple className="mr-2 h-4 w-4 text-maternal-green-500" /> Nutrition Tips
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => { setCreateTipType('video'); setIsCreateModalOpen(true); }} className="hover:bg-maternal-brown-100">
                <Video className="mr-2 h-4 w-4 text-maternal-brown-500" /> Health Videos
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
            <DialogContent className="max-w-lg w-full rounded-xl p-6">
              <DialogHeader>
                <DialogTitle className="text-lg md:text-xl font-bold text-maternal-blue-700">Create {createTipType === 'health' ? 'Health Tip' : createTipType === 'nutrition' ? 'Nutrition Tip' : createTipType === 'video' ? 'Health Video' : ''}</DialogTitle>
              </DialogHeader>
              <form className="space-y-4" onSubmit={e => { e.preventDefault(); handleCreateTip(); }}>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-maternal-blue-700 mb-1">Weeks</label>
                    <Select value={tipWeeks} onValueChange={setTipWeeks}>
                      <SelectTrigger><SelectValue placeholder="Any week (optional)" /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="any">Any week</SelectItem>
                        {[...Array(40)].map((_, i) => (
                          <SelectItem key={i + 1} value={(i + 1).toString()}>{`Week ${i + 1}`}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-maternal-blue-700 mb-1">Trimester</label>
                    <Select value={tipTrimester} onValueChange={setTipTrimester}>
                      <SelectTrigger><SelectValue placeholder="Any trimester (optional)" /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="any">Any trimester</SelectItem>
                        <SelectItem value="1">Trimester 1</SelectItem>
                        <SelectItem value="2">Trimester 2</SelectItem>
                        <SelectItem value="3">Trimester 3</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-maternal-blue-700 mb-1">Visit / Care Type</label>
                    <Select value={tipVisit} onValueChange={setTipVisit}>
                      <SelectTrigger><SelectValue placeholder="Any visit or care type (optional)" /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="any">Any visit or care type</SelectItem>
                        {[...Array(8)].map((_, i) => (
                          <SelectItem key={i + 1} value={`visit-${i + 1}`}>{`Visit ${i + 1}`}</SelectItem>
                        ))}
                        <SelectItem value="child-care">Child Care</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-maternal-blue-700 mb-1">Title</label>
                  <Input value={tipTitle} onChange={e => setTipTitle(e.target.value)} placeholder="Enter tip title" required />
                </div>
                <div>
                  <label className="block text-sm font-medium text-maternal-blue-700 mb-1">Message</label>
                  <Textarea value={tipContent} onChange={e => setTipContent(e.target.value)} placeholder="Enter tip message" required />
                </div>
                <div>
                  <label className="block text-sm font-medium text-maternal-blue-700 mb-1">Schedule Tip</label>
                  <Input type="datetime-local" value={tipScheduleDate} onChange={e => setTipScheduleDate(e.target.value)} />
                </div>
                {createTipType === 'health' && (
                  <div>
                    <label className="block text-sm font-medium text-maternal-blue-700 mb-1">Category</label>
                    <Select value={categoryType} onValueChange={setCategoryType}>
                      <SelectTrigger><SelectValue placeholder="Select category" /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="General Health">General Health</SelectItem>
                        <SelectItem value="Physical Health">Physical Health</SelectItem>
                        <SelectItem value="Mental Health">Mental Health</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                )}
                {createTipType === 'nutrition' && (
        <div>
                    <label className="block text-sm font-medium text-maternal-green-700 mb-1">Category</label>
                    <Select value={nutritionType} onValueChange={setNutritionType}>
                      <SelectTrigger><SelectValue placeholder="Select category" /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Pregnancy Nutrition">Pregnancy Nutrition</SelectItem>
                        <SelectItem value="Snacks">Snacks</SelectItem>
                        <SelectItem value="Safety">Safety</SelectItem>
                      </SelectContent>
                    </Select>
        </div>
                )}
                <Button type="submit" className="w-full bg-maternal-blue-600 hover:bg-maternal-blue-700 text-white font-semibold shadow">Submit</Button>
              </form>
            </DialogContent>
          </Dialog>
        </div>
      </div>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card className="bg-white border-0 shadow hover:shadow-lg transition-shadow group">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-semibold text-maternal-blue-700 flex items-center gap-2">
              <Heart className="h-5 w-5 text-maternal-blue-400 group-hover:text-maternal-blue-600 transition-colors" /> Health Tips
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-maternal-blue-600">{healthTipsCount}</div>
            <p className="text-xs text-maternal-blue-400 mt-1">Covering various health topics</p>
          </CardContent>
        </Card>
        <Card className="bg-white border-0 shadow hover:shadow-lg transition-shadow group">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-semibold text-maternal-green-700 flex items-center gap-2">
              <Apple className="h-5 w-5 text-maternal-green-400 group-hover:text-maternal-green-600 transition-colors" /> Nutrition Advice
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-maternal-green-600">{nutritionTipsCount}</div>
            <p className="text-xs text-maternal-green-400 mt-1">Trimester-specific diet plans</p>
          </CardContent>
        </Card>
        <Card className="bg-white border-0 shadow hover:shadow-lg transition-shadow group">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-semibold text-maternal-brown-700 flex items-center gap-2">
              <Video className="h-5 w-5 text-maternal-brown-400 group-hover:text-maternal-brown-600 transition-colors" /> Health Videos
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-maternal-brown-600">{healthVideosCount}</div>
            <p className="text-xs text-maternal-brown-400 mt-1">Educational video resources</p>
          </CardContent>
        </Card>
      </div>
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <TabsList className="flex flex-wrap gap-2 bg-maternal-blue-100 p-2 rounded-lg">
          <TabsTrigger value="health-tips" className="flex items-center gap-2 px-4 py-2 rounded-lg text-maternal-blue-700 data-[state=active]:bg-maternal-blue-600 data-[state=active]:text-white transition-colors">
            <Heart className="h-4 w-4" /> Health Tips
          </TabsTrigger>
          <TabsTrigger value="nutrition-tips" className="flex items-center gap-2 px-4 py-2 rounded-lg text-maternal-green-700 data-[state=active]:bg-maternal-green-600 data-[state=active]:text-white transition-colors">
            <Apple className="h-4 w-4" /> Nutrition Tips
          </TabsTrigger>
          <TabsTrigger value="health-videos" className="flex items-center gap-2 px-4 py-2 rounded-lg text-maternal-brown-700 data-[state=active]:bg-maternal-brown-600 data-[state=active]:text-white transition-colors">
            <Video className="h-4 w-4" /> Health Videos
          </TabsTrigger>
        </TabsList>
        <TabsContent value="health-tips" className="space-y-4">
          <HealthTipsTab 
            tips={healthTips
              .filter(t => t.category === 'health')
              .sort((a, b) => {
                const weekA = a.weeks && !isNaN(Number(a.weeks)) ? Number(a.weeks) : 9999;
                const weekB = b.weeks && !isNaN(Number(b.weeks)) ? Number(b.weeks) : 9999;
                return weekA - weekB;
              })}
            onSendTip={handleSendTip}
            onEditTip={handleEditTip}
            onDeleteTip={handleDeleteTip}
            searchTerm={searchTerm}
            setSearchTerm={setSearchTerm}
            filterStage={filterStage}
            setFilterStage={setFilterStage}
          />
        </TabsContent>
        <TabsContent value="nutrition-tips" className="space-y-4">
          <NutritionTipsTab 
            tips={healthTips
              .filter(t => t.category === 'nutrition')
              .sort((a, b) => {
                const weekA = a.weeks && !isNaN(Number(a.weeks)) ? Number(a.weeks) : 9999;
                const weekB = b.weeks && !isNaN(Number(b.weeks)) ? Number(b.weeks) : 9999;
                return weekA - weekB;
              })}
            onSendTip={handleSendTip}
            onEditTip={handleEditTip}
            onDeleteTip={handleDeleteTip}
            searchTerm={searchTerm}
            setSearchTerm={setSearchTerm}
            filterStage={filterStage}
            setFilterStage={setFilterStage}
          />
        </TabsContent>
        <TabsContent value="health-videos" className="space-y-4">
          <div className="bg-white rounded-lg shadow p-6 flex flex-col items-center justify-center min-h-[200px]">
            <Video className="h-10 w-10 text-maternal-brown-400 mb-2" />
            <h3 className="text-lg font-semibold text-maternal-brown-700">Health Videos</h3>
            <p className="text-maternal-brown-500">Coming soon: A library of educational videos for expectant mothers.</p>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}

// Health Tips Tab Component
function HealthTipsTab({ 
  tips, 
  onSendTip, 
  onEditTip, 
  onDeleteTip,
  searchTerm, 
  setSearchTerm, 
  filterStage, 
  setFilterStage 
}: {
  tips: HealthTip[]
  onSendTip: (tip: HealthTip) => void
  onEditTip: (tip: HealthTip) => void
  onDeleteTip: (tip: HealthTip) => void
  searchTerm: string
  setSearchTerm: (term: string) => void
  filterStage: string
  setFilterStage: (stage: string) => void
}) {
  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search health tips..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Select value={filterStage} onValueChange={setFilterStage}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Filter by stage" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Stages</SelectItem>
            <SelectItem value="first-trimester">First Trimester</SelectItem>
            <SelectItem value="second-trimester">Second Trimester</SelectItem>
            <SelectItem value="third-trimester">Third Trimester</SelectItem>
            <SelectItem value="delivery">Delivery</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Tips Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {tips.map((tip, idx) => (
          <Card key={tip.id} className="hover:shadow-md transition-shadow relative">
            <div className="absolute top-2 left-2 flex flex-col items-center">
              <div className="bg-maternal-blue-100 text-maternal-blue-700 rounded-full w-7 h-7 flex items-center justify-center font-bold text-sm shadow">{idx + 1}</div>
              <div className="mt-1 text-xs text-maternal-blue-600 font-semibold">{tip.weeks ? `Week ${String(tip.weeks)}` : ''}</div>
            </div>
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2">
                  <Heart className="h-5 w-5 text-red-500" />
                  <Badge className={getStageColor(tip.targetStage)}>
                    {tip.targetStage ? tip.targetStage.replace('-', ' ') : 'All Stages'}
                  </Badge>
                </div>
                <div className="flex gap-1">
                  <Button variant="ghost" size="sm" onClick={() => onEditTip(tip)}>
                    <Edit className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="sm" onClick={() => onSendTip(tip)}>
                    <Send className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="sm" onClick={() => onDeleteTip(tip)}>
                    <Trash2 className="h-4 w-4 text-red-500" />
                  </Button>
                </div>
              </div>
              <CardTitle className="text-lg flex flex-col gap-1">
                {tip.title}
                {tip.categoryType && (
                  <span className="text-xs font-medium text-maternal-blue-500 bg-maternal-blue-100 rounded px-2 py-0.5 w-fit">{tip.categoryType}</span>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground line-clamp-3">
                {tip.content}
              </p>
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Sent {tip.sentCount} times</span>
                <span>
                  {tip.createdAt
                    ? (tip.createdAt.toDate
                        ? tip.createdAt.toDate().toLocaleDateString()
                        : new Date(tip.createdAt).toLocaleDateString())
                    : 'N/A'}
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {tips.length === 0 && (
        <Card>
          <CardContent className="text-center py-12">
            <Heart className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-medium mb-2">No health tips found</h3>
            <p className="text-muted-foreground">Create your first health tip to get started.</p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

// Nutrition Tips Tab Component
function NutritionTipsTab({ 
  tips, 
  onSendTip, 
  onEditTip, 
  onDeleteTip,
  searchTerm, 
  setSearchTerm, 
  filterStage, 
  setFilterStage 
}: {
  tips: HealthTip[]
  onSendTip: (tip: HealthTip) => void
  onEditTip: (tip: HealthTip) => void
  onDeleteTip: (tip: HealthTip) => void
  searchTerm: string
  setSearchTerm: (term: string) => void
  filterStage: string
  setFilterStage: (stage: string) => void
}) {
  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search nutrition tips..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Select value={filterStage} onValueChange={setFilterStage}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Filter by stage" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Stages</SelectItem>
            <SelectItem value="first-trimester">First Trimester</SelectItem>
            <SelectItem value="second-trimester">Second Trimester</SelectItem>
            <SelectItem value="third-trimester">Third Trimester</SelectItem>
            <SelectItem value="delivery">Delivery</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Tips Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {tips.map((tip, idx) => (
          <Card key={tip.id} className="hover:shadow-md transition-shadow relative">
            <div className="absolute top-2 left-2 flex flex-col items-center">
              <div className="bg-maternal-green-100 text-maternal-green-700 rounded-full w-7 h-7 flex items-center justify-center font-bold text-sm shadow">{idx + 1}</div>
              <div className="mt-1 text-xs text-maternal-green-600 font-semibold">{tip.weeks ? `Week ${String(tip.weeks)}` : ''}</div>
            </div>
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2">
                  <Apple className="h-5 w-5 text-green-500" />
                  <Badge className={getStageColor(tip.targetStage)}>
                    {tip.targetStage ? tip.targetStage.replace('-', ' ') : 'All Stages'}
                  </Badge>
                </div>
                <div className="flex gap-1">
                  <Button variant="ghost" size="sm" onClick={() => onEditTip(tip)}>
                    <Edit className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="sm" onClick={() => onSendTip(tip)}>
                    <Send className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="sm" onClick={() => onDeleteTip(tip)}>
                    <Trash2 className="h-4 w-4 text-red-500" />
                  </Button>
                </div>
              </div>
              <CardTitle className="text-lg flex flex-col gap-1">
                {tip.title}
                {tip.nutritionType && (
                  <span className="text-xs font-medium text-maternal-green-600 bg-maternal-green-100 rounded px-2 py-0.5 w-fit">{tip.nutritionType}</span>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground line-clamp-3">
                {tip.content}
              </p>
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Sent {tip.sentCount} times</span>
                <span>
                  {tip.createdAt
                    ? (tip.createdAt.toDate
                        ? tip.createdAt.toDate().toLocaleDateString()
                        : new Date(tip.createdAt).toLocaleDateString())
                    : 'N/A'}
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {tips.length === 0 && (
        <Card>
          <CardContent className="text-center py-12">
            <Apple className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-medium mb-2">No nutrition tips found</h3>
            <p className="text-muted-foreground">Create your first nutrition tip to get started.</p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

function getStageColor(stage: string) {
  switch (stage) {
    case "first-trimester": return "bg-blue-100 text-blue-800"
    case "second-trimester": return "bg-green-100 text-green-800"
    case "third-trimester": return "bg-purple-100 text-purple-800"
    case "delivery": return "bg-orange-100 text-orange-800"
    default: return "bg-gray-100 text-gray-800"
  }
} 