import React, { useState, useEffect, useMemo } from "react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "./ui/card";
import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from "./ui/table";
import { Badge } from "./ui/badge";
import { 
  AlertTriangle, 
  Users, 
  Calendar, 
  Clock, 
  Search, 
  UserX, 
  Eye, 
  ChevronDown, 
  ChevronUp,
  MessageSquare,
  Building,
  User,
  Phone,
  CalendarDays,
  FileText,
  Shield,
  File,
  Download,
  ExternalLink,
  Paperclip
} from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "./ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Separator } from "./ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { Textarea } from "./ui/textarea";
import { Label } from "./ui/label";

interface Report {
  id: string;
  clientName: string;
  clientNumber: string;
  createdAt: string;
  description: string;
  facilityName: string;
  isAnonymous: boolean;
  phoneNumber: string;
  reportType: string;
  fileUrls: string[];
  isRead: boolean;
  reply?: string;
  replySentAt?: string;
  replySentBy?: string;
}

export default function ReportList() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [searchField, setSearchField] = useState("all");
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set());
  const [readFilter, setReadFilter] = useState<"all" | "read" | "unread">("all");
  const [sortBy, setSortBy] = useState<"date" | "read">("date");
  const [replyMessage, setReplyMessage] = useState("");
  const [isReplyModalOpen, setIsReplyModalOpen] = useState(false);
  const [replyingTo, setReplyingTo] = useState<Report | null>(null);
  const [isSendingReply, setIsSendingReply] = useState(false);

  useEffect(() => {
    async function fetchReports() {
      setLoading(true);
      setError(null);
      try {
        // Simulate fetching reports from a local state or dummy data
        const dummyReports: Report[] = [
          {
            id: "1",
            clientName: "John Doe",
            clientNumber: "123456",
            createdAt: "2023-10-26T10:00:00Z",
            description: "I observed a nurse being rude to a patient. The patient was in a wheelchair and the nurse pushed it aggressively. This is unacceptable behavior.",
            facilityName: "Hospital A",
            isAnonymous: false,
            phoneNumber: "123-456-7890",
            reportType: "Complaint",
            fileUrls: ["https://example.com/report1.pdf", "https://example.com/report2.docx"],
            isRead: false,
            reply: "Thank you for your report. We have received it and are investigating the incident. We will take appropriate action.",
            replySentAt: "2023-10-26T10:30:00Z",
            replySentBy: "admin"
          },
          {
            id: "2",
            clientName: "Jane Smith",
            clientNumber: "789012",
            createdAt: "2023-10-25T14:00:00Z",
            description: "I found a patient's personal belongings left unattended in the waiting area. This is a security risk.",
            facilityName: "Clinic B",
            isAnonymous: true,
            phoneNumber: "",
            reportType: "Incident",
            fileUrls: ["https://example.com/report3.jpg"],
            isRead: true,
            reply: "Thank you for your report. We have received it and are investigating the incident. We will take appropriate action.",
            replySentAt: "2023-10-25T14:30:00Z",
            replySentBy: "admin"
          },
          {
            id: "3",
            clientName: "Peter Jones",
            clientNumber: "345678",
            createdAt: "2023-10-24T09:00:00Z",
            description: "I noticed a doctor prescribing medication without proper consultation. The patient was in pain and the doctor insisted on giving it.",
            facilityName: "Hospital A",
            isAnonymous: false,
            phoneNumber: "987-654-3210",
            reportType: "Feedback",
            fileUrls: [],
            isRead: true,
            reply: "Thank you for your feedback. We have received it and are reviewing the doctor's conduct. We will ensure proper consultation in the future.",
            replySentAt: "2023-10-24T09:30:00Z",
            replySentBy: "admin"
          },
          {
            id: "4",
            clientName: "Anonymous",
            clientNumber: "901234",
            createdAt: "2023-10-23T11:00:00Z",
            description: "I observed a staff member stealing patient belongings. This is a serious security breach.",
            facilityName: "Clinic B",
            isAnonymous: true,
            phoneNumber: "",
            reportType: "Incident",
            fileUrls: ["https://example.com/report4.txt"],
            isRead: false,
            reply: "Thank you for your report. We have received it and are investigating the incident. We will take appropriate action.",
            replySentAt: "2023-10-23T11:30:00Z",
            replySentBy: "admin"
          },
        ];
        setReports(dummyReports);
      } catch (err) {
        setError("Failed to fetch reports.");
      } finally {
        setLoading(false);
      }
    }
    fetchReports();
  }, []);

  const handleRowClick = (report: Report) => {
    if (!report.isRead) {
      markAsRead(report.id);
    }
    setSelectedReport({ ...report, isRead: true });
    setIsModalOpen(true);
  };

  const markAsRead = async (reportId: string) => {
    try {
      console.log('Marking report as read:', reportId);
      
      // Find the report to get user details
      const report = reports.find(r => r.id === reportId);
      if (!report) {
        console.error('Report not found:', reportId);
        return;
      }
      
      // Update local state immediately for better UX
      setReports(prev => prev.map(report => 
        report.id === reportId ? { ...report, isRead: true } : report
      ));
      
      // Create the response message
      const responseMessage = `Dear ${report.isAnonymous ? 'Anonymous Reporter' : report.clientName},

Thank you for submitting your report regarding ${report.facilityName}. We have received your report and our team is currently reviewing the information you provided.

We take all reports seriously and are committed to addressing your concerns appropriately. You will receive further updates on the status of your report.

If you have any additional information or questions, please don't hesitate to contact us.

Best regards,
The HealthMama Support Team`;

      // Update Firebase - create isRead and reply fields
      // const reportRef = doc(db, "report", reportId); // Removed Firebase
      // console.log('Firebase document reference:', reportRef); // Removed Firebase
      
      // const updateData = { // Removed Firebase
      //   isRead: true,
      //   lastReadAt: new Date().toISOString(),
      //   reply: responseMessage,
      //   replySentAt: new Date().toISOString(),
      //   replySentBy: "admin"
      // };
      
      // console.log('Creating/updating isRead and reply fields with data:', updateData); // Removed Firebase
      // await updateDoc(reportRef, updateData); // Removed Firebase
      
      // console.log('Successfully marked report as read and sent reply in Firebase'); // Removed Firebase
      
      // Show success notification
      const successMessage = `Report marked as read and response sent to ${report.isAnonymous ? 'Anonymous Reporter' : report.clientName}`;
      console.log(successMessage);
      
    } catch (error: any) {
      console.error("Error marking report as read:", error);
      console.error("Error code:", error.code);
      console.error("Error message:", error.message);
      
      // Revert local state if Firebase update failed
      setReports(prev => prev.map(report => 
        report.id === reportId ? { ...report, isRead: false } : report
      ));
      
      // Show more specific error message
      let errorMessage = "Failed to mark report as read. Please try again.";
      // if (error.code === 'permission-denied') { // Removed Firebase
      //   errorMessage = "Permission denied. Please update your Firestore security rules to allow write access to the 'report' collection. Go to Firebase Console → Firestore Database → Rules and add: allow read, write: if true;"; // Removed Firebase
      // } else if (error.code === 'not-found') { // Removed Firebase
      //   errorMessage = "Report not found. It may have been deleted."; // Removed Firebase
      // } else if (error.code === 'unavailable') { // Removed Firebase
      //   errorMessage = "Network error. Please check your internet connection."; // Removed Firebase
      // }
      
      alert(errorMessage);
    }
  };

  const markAsUnread = async (reportId: string) => {
    try {
      console.log('Marking report as unread:', reportId);
      
      // Update local state immediately for better UX
      setReports(prev => prev.map(report => 
        report.id === reportId ? { ...report, isRead: false } : report
      ));
      
      // Update Firebase - create isRead field if it doesn't exist
      // const reportRef = doc(db, "report", reportId); // Removed Firebase
      // console.log('Firebase document reference:', reportRef); // Removed Firebase
      
      // const updateData = { // Removed Firebase
      //   isRead: false,
      //   lastReadAt: null
      // };
      
      // console.log('Creating/updating isRead field with data:', updateData); // Removed Firebase
      // await updateDoc(reportRef, updateData); // Removed Firebase
      
      // console.log('Successfully marked report as unread in Firebase'); // Removed Firebase
    } catch (error: any) {
      console.error("Error marking report as unread:", error);
      console.error("Error code:", error.code);
      console.error("Error message:", error.message);
      
      // Revert local state if Firebase update failed
      setReports(prev => prev.map(report => 
        report.id === reportId ? { ...report, isRead: true } : report
      ));
      
      // Show more specific error message
      let errorMessage = "Failed to mark report as unread. Please try again.";
      // if (error.code === 'permission-denied') { // Removed Firebase
      //   errorMessage = "Permission denied. Please update your Firestore security rules to allow write access to the 'report' collection. Go to Firebase Console → Firestore Database → Rules and add: allow read, write: if true;"; // Removed Firebase
      // } else if (error.code === 'not-found') { // Removed Firebase
      //   errorMessage = "Report not found. It may have been deleted."; // Removed Firebase
      // } else if (error.code === 'unavailable') { // Removed Firebase
      //   errorMessage = "Network error. Please check your internet connection."; // Removed Firebase
      // }
      
      alert(errorMessage);
    }
  };

  const initializeReadStatus = async () => {
    try {
      console.log('Initializing read status for all reports...');
      
      // Get all reports that don't have isRead field
      const reportsToUpdate = reports.filter(report => report.isRead === undefined);
      
      if (reportsToUpdate.length === 0) {
        alert('All reports already have read status initialized.');
        return;
      }
      
      console.log(`Found ${reportsToUpdate.length} reports to initialize`);
      
      // Update each report
      for (const report of reportsToUpdate) {
        // const reportRef = doc(db, "report", report.id); // Removed Firebase
        // await updateDoc(reportRef, { // Removed Firebase
        //   isRead: false
        // });
        console.log(`Initialized report ${report.id}`);
      }
      
      // Refresh the reports list
      // const snapshot = await getDocs(collection(db, "report")); // Removed Firebase
      const fetched: Report[] = reports.map(report => { // Use local state
        return {
          id: report.id,
          clientName: report.clientName || "-",
          clientNumber: report.clientNumber || "-",
          createdAt: report.createdAt || "-",
          description: report.description || "-",
          facilityName: report.facilityName || "-",
          isAnonymous: report.isAnonymous ?? true,
          phoneNumber: report.phoneNumber || "-",
          reportType: report.reportType || "-",
          fileUrls: report.fileUrls || [],
          isRead: report.isRead ?? false,
          reply: report.reply,
          replySentAt: report.replySentAt,
          replySentBy: report.replySentBy,
        };
      });
      setReports(fetched);
      
      alert(`Successfully initialized read status for ${reportsToUpdate.length} reports.`);
    } catch (error: any) {
      console.error("Error initializing read status:", error);
      alert("Failed to initialize read status. Please try again.");
    }
  };

  const toggleRowExpansion = (reportId: string) => {
    const newExpanded = new Set(expandedRows);
    if (newExpanded.has(reportId)) {
      newExpanded.delete(reportId);
    } else {
      newExpanded.add(reportId);
    }
    setExpandedRows(newExpanded);
  };

  const truncateText = (text: string, maxLength: number = 80) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + "...";
  };

  const getFileInfo = (url: string) => {
    try {
      const urlObj = new URL(url);
      const pathname = urlObj.pathname;
      const filename = pathname.split('/').pop() || 'Document';
      const extension = filename.split('.').pop()?.toLowerCase() || '';
      
      // Get file type icon and color
      const fileTypes: { [key: string]: { icon: string; color: string; label: string } } = {
        'pdf': { icon: '📄', color: 'text-red-600', label: 'PDF Document' },
        'doc': { icon: '📝', color: 'text-blue-600', label: 'Word Document' },
        'docx': { icon: '📝', color: 'text-blue-600', label: 'Word Document' },
        'jpg': { icon: '🖼️', color: 'text-green-600', label: 'Image' },
        'jpeg': { icon: '🖼️', color: 'text-green-600', label: 'Image' },
        'png': { icon: '🖼️', color: 'text-green-600', label: 'Image' },
        'gif': { icon: '🖼️', color: 'text-green-600', label: 'Image' },
        'mp4': { icon: '🎥', color: 'text-purple-600', label: 'Video' },
        'avi': { icon: '🎥', color: 'text-purple-600', label: 'Video' },
        'mov': { icon: '🎥', color: 'text-purple-600', label: 'Video' },
        'txt': { icon: '📄', color: 'text-gray-600', label: 'Text File' },
        'xlsx': { icon: '📊', color: 'text-green-600', label: 'Excel Spreadsheet' },
        'xls': { icon: '📊', color: 'text-green-600', label: 'Excel Spreadsheet' }
      };
      
      const fileType = fileTypes[extension] || { icon: '📎', color: 'text-gray-600', label: 'Document' };
      
      return {
        filename: filename.length > 30 ? filename.substring(0, 30) + '...' : filename,
        extension,
        fileType,
        url
      };
    } catch {
      return {
        filename: 'Document',
        extension: '',
        fileType: { icon: '📎', color: 'text-gray-600', label: 'Document' },
        url
      };
    }
  };

  const searchFields = [
    { value: "all", label: "All Fields" },
    { value: "clientName", label: "Client Name" },
    { value: "facilityName", label: "Facility" },
    { value: "reportType", label: "Type" },
    { value: "createdAt", label: "Date" },
    { value: "description", label: "Description" },
    { value: "fileUrls", label: "Documents" },
  ];

  const filteredReports = useMemo(() => {
    let filtered = reports;

    // Apply read status filter
    if (readFilter !== "all") {
      filtered = filtered.filter(report => 
        readFilter === "read" ? report.isRead : !report.isRead
      );
    }

    // Apply search filter
    const lower = searchTerm.toLowerCase();
    if (searchTerm.trim()) {
      filtered = filtered.filter(r => {
      const checkField = (key: keyof Report) => {
        const value = r[key];
        if (typeof value === 'string') {
          return value.toLowerCase().includes(lower);
        }
        return false;
      };

      if (searchField === "all") {
        return (
          checkField('clientName') ||
          checkField('clientNumber') ||
          checkField('facilityName') ||
          checkField('reportType') ||
          checkField('description') ||
            checkField('createdAt') ||
            (Array.isArray(r.fileUrls) && r.fileUrls.some(url => url.toLowerCase().includes(lower)))
        );
        } else if (searchField === "fileUrls") {
          return Array.isArray(r.fileUrls) && r.fileUrls.some(url => url.toLowerCase().includes(lower));
      } else {
        return checkField(searchField as keyof Report);
      }
    });
    }

    // Apply sorting
    filtered.sort((a, b) => {
      if (sortBy === "read") {
        // Sort by read status (unread first), then by date
        if (a.isRead !== b.isRead) {
          return a.isRead ? 1 : -1;
        }
      }
      
      // Sort by date (newest first)
      if (a.createdAt && b.createdAt) {
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(); // Compare Date objects
      }
      return 0;
    });

    return filtered;
  }, [reports, searchTerm, searchField, readFilter, sortBy]);

  const anonymousReportsCount = useMemo(() => {
    return filteredReports.filter(report => report.isAnonymous).length;
  }, [filteredReports]);

  const getReportTypeColor = (type: string) => {
    const colors: { [key: string]: string } = {
      'complaint': 'bg-red-100 text-red-800 border-red-200',
      'suggestion': 'bg-blue-100 text-blue-800 border-blue-200',
      'feedback': 'bg-green-100 text-green-800 border-green-200',
      'incident': 'bg-orange-100 text-orange-800 border-orange-200',
      'default': 'bg-gray-100 text-gray-800 border-gray-200'
    };
    return colors[type.toLowerCase()] || colors.default;
  };

  const handleReply = (report: Report) => {
    setReplyingTo(report);
    setReplyMessage(`Dear ${report.isAnonymous ? 'Anonymous Reporter' : report.clientName},

Thank you for submitting your report. We have received your ${report.reportType.toLowerCase()} regarding ${report.facilityName}.

Our team is currently reviewing the information you provided and will take appropriate action. We take all reports seriously and are committed to addressing your concerns.

You will receive further updates on the status of your report within 3-5 business days.

If you have any additional information or questions, please don't hesitate to contact us.

Best regards,
The HealthMama Support Team`);
    setIsReplyModalOpen(true);
  };

  const sendReply = async () => {
    if (!replyingTo || !replyMessage.trim()) return;
    
    setIsSendingReply(true);
    try {
      // Update the report document with the reply
      // const reportRef = doc(db, "report", replyingTo.id); // Removed Firebase
      // await updateDoc(reportRef, { // Removed Firebase
      //   reply: replyMessage,
      //   replySentAt: new Date().toISOString(),
      //   replySentBy: "admin",
      //   isRead: true,
      //   lastReadAt: new Date().toISOString()
      // });

      // Update local state
      setReports(prev => prev.map(report => 
        report.id === replyingTo.id ? { 
          ...report, 
          isRead: true,
          reply: replyMessage,
          replySentAt: new Date().toISOString(),
          replySentBy: "admin"
        } : report
      ));
      
      // Close modal and reset
      setIsReplyModalOpen(false);
      setReplyingTo(null);
      setReplyMessage("");
      
      // Show success message
      alert("Reply sent successfully!");
    } catch (error) {
      console.error("Error sending reply:", error);
      alert("Failed to send reply. Please try again.");
    } finally {
      setIsSendingReply(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-[400px] flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-maternal-green-600"></div>
          <p className="text-muted-foreground">Loading reports...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-[400px] flex items-center justify-center">
        <div className="text-center space-y-4">
          <AlertTriangle className="h-12 w-12 text-red-500 mx-auto" />
          <p className="text-red-600 font-medium">{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header Section */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="space-y-2">
          <h1 className="text-3xl lg:text-4xl font-bold text-gray-900">Reports Dashboard</h1>
          <p className="text-gray-600 text-lg">
            Monitor and manage whistleblower reports from healthcare facilities
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <Badge variant="secondary" className="text-sm">
            <Shield className="w-4 h-4 mr-1" />
            Secure & Anonymous
          </Badge>
          {filteredReports.filter(r => !r.isRead).length > 0 && (
            <Button
              variant="outline"
              size="sm"
              onClick={async () => {
                const unreadReports = filteredReports.filter(r => !r.isRead);
                for (const report of unreadReports) {
                  await markAsRead(report.id);
                }
              }}
              className="text-orange-600 border-orange-200 hover:bg-orange-50"
            >
              <Eye className="h-4 w-4 mr-1" />
              Mark All as Read & Respond
            </Button>
          )}
        </div>
      </div>

      {/* Enhanced Statistics Cards */}
      <div className="grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-4">
        <Card className="relative overflow-hidden border-0 shadow-lg bg-gradient-to-br from-red-500 to-red-600 text-white">
          <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-16 translate-x-16"></div>
          <CardHeader className="relative pb-2">
            <CardTitle className="text-sm font-medium flex items-center">
              <AlertTriangle className="h-4 w-4 mr-2" />
              Total Reports
            </CardTitle>
          </CardHeader>
          <CardContent className="relative">
            <div className="text-3xl font-bold mb-1">{filteredReports.length}</div>
            <p className="text-red-100 text-sm">Active submissions</p>
          </CardContent>
        </Card>

        <Card className="relative overflow-hidden border-0 shadow-lg bg-gradient-to-br from-orange-500 to-orange-600 text-white">
          <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-16 translate-x-16"></div>
          <CardHeader className="relative pb-2">
            <CardTitle className="text-sm font-medium flex items-center">
              <Eye className="h-4 w-4 mr-2" />
              Unread Reports
            </CardTitle>
          </CardHeader>
          <CardContent className="relative">
            <div className="text-3xl font-bold mb-1">{filteredReports.filter(r => !r.isRead).length}</div>
            <p className="text-orange-100 text-sm">Require attention</p>
          </CardContent>
        </Card>

        <Card className="relative overflow-hidden border-0 shadow-lg bg-gradient-to-br from-blue-500 to-blue-600 text-white">
          <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-16 translate-x-16"></div>
          <CardHeader className="relative pb-2">
            <CardTitle className="text-sm font-medium flex items-center">
              <Users className="h-4 w-4 mr-2" />
              Unique Reporters
            </CardTitle>
          </CardHeader>
          <CardContent className="relative">
            <div className="text-3xl font-bold mb-1">{[...new Set(filteredReports.map(r => r.clientNumber))].length}</div>
            <p className="text-blue-100 text-sm">Individual users</p>
          </CardContent>
        </Card>

        <Card className="relative overflow-hidden border-0 shadow-lg bg-gradient-to-br from-emerald-500 to-emerald-600 text-white">
          <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-16 translate-x-16"></div>
          <CardHeader className="relative pb-2">
            <CardTitle className="text-sm font-medium flex items-center">
              <Building className="h-4 w-4 mr-2" />
              Facilities
            </CardTitle>
          </CardHeader>
          <CardContent className="relative">
            <div className="text-3xl font-bold mb-1">{[...new Set(filteredReports.map(r => r.facilityName))].length}</div>
            <p className="text-emerald-100 text-sm">Healthcare centers</p>
          </CardContent>
        </Card>
      </div>

      {/* Enhanced Search & Filter */}
      <Card className="border-0 shadow-sm bg-white/50 backdrop-blur-sm">
        <CardContent className="pt-6">
          <div className="flex flex-col lg:flex-row items-stretch lg:items-center space-y-3 lg:space-y-0 lg:space-x-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
                placeholder="Search reports by content, facility, or reporter..."
                className="pl-10 h-12 border-gray-200 focus:border-maternal-green-500 focus:ring-maternal-green-500"
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
          />
        </div>
        <Select value={searchField} onValueChange={setSearchField}>
              <SelectTrigger className="w-full lg:w-[200px] h-12 border-gray-200">
                <SelectValue placeholder="Filter by field" />
          </SelectTrigger>
          <SelectContent>
            {searchFields.map(field => (
              <SelectItem key={field.value} value={field.value}>
                {field.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
            <Select value={readFilter} onValueChange={(value: "all" | "read" | "unread") => setReadFilter(value)}>
              <SelectTrigger className="w-full lg:w-[150px] h-12 border-gray-200">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Reports</SelectItem>
                <SelectItem value="unread">Unread</SelectItem>
                <SelectItem value="read">Read</SelectItem>
              </SelectContent>
            </Select>
            <Select value={sortBy} onValueChange={(value: "date" | "read") => setSortBy(value)}>
              <SelectTrigger className="w-full lg:w-[150px] h-12 border-gray-200">
                <SelectValue placeholder="Sort by" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="date">Date (Newest)</SelectItem>
                <SelectItem value="read">Read Status</SelectItem>
          </SelectContent>
        </Select>
      </div>
        </CardContent>
      </Card>

      {/* Enhanced Reports Table */}
      <Card className="border-0 shadow-lg overflow-hidden">
        <CardHeader className="bg-gradient-to-r from-gray-50 to-gray-100 border-b">
          <CardTitle className="flex items-center text-xl">
            <MessageSquare className="h-5 w-5 mr-2 text-maternal-green-600" />
            Reports Overview
          </CardTitle>
          <CardDescription className="text-gray-600">
            Showing {filteredReports.length} of {reports.length} reports. Click "View" to see full report details or expand row for quick preview.
          </CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="bg-gray-50 hover:bg-gray-50">
                  <TableHead className="font-semibold text-gray-700 text-base">Status</TableHead>
                  <TableHead className="font-semibold text-gray-700 text-base">Reporter</TableHead>
                  <TableHead className="font-semibold text-gray-700 text-base">Facility</TableHead>
                  <TableHead className="font-semibold text-gray-700 text-base">Type</TableHead>
                  <TableHead className="font-semibold text-gray-700 text-base">Date</TableHead>
                  <TableHead className="font-semibold text-gray-700 text-base">Description</TableHead>
                  <TableHead className="font-semibold text-gray-700 text-base">Documents</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredReports.map((report: Report) => {
                  const isExpanded = expandedRows.has(report.id);
                  return (
                    <React.Fragment key={report.id}>
                  <TableRow
                        className="hover:bg-maternal-green-50/50 transition-colors border-b cursor-pointer"
                        onClick={e => {
                          // Prevent row click if clicking on a button inside the row
                          if ((e.target as HTMLElement).closest('button')) return;
                          handleRowClick(report);
                        }}
                      >
                        <TableCell className="py-4">
                          <div className="flex items-center space-x-2">
                            <div className={`w-3 h-3 rounded-full ${report.isRead ? 'bg-gray-400' : 'bg-orange-500 animate-pulse'}`}></div>
                            <Badge className={`${report.isRead ? "bg-gray-100 text-gray-700 border-gray-300" : "bg-orange-100 text-orange-700 border-orange-300"} text-sm`}>
                              {report.isRead ? "Read" : "Unread"}
                            </Badge>
                            {report.reply && (
                              <Badge className="bg-green-100 text-green-700 border-green-300 text-sm">
                                <MessageSquare className="w-4 h-4 mr-1" />
                                Replied
                              </Badge>
                            )}
                          </div>
                        </TableCell>
                        <TableCell className="py-4">
                          <div className="flex items-center space-x-3">
                            <div className="w-10 h-10 bg-maternal-green-100 rounded-full flex items-center justify-center">
                              <User className="w-5 h-5 text-maternal-green-600" />
                            </div>
                            <div>
                              <div className="font-medium text-gray-900 text-base">
                                {report.isAnonymous ? "Anonymous" : report.clientName}
                              </div>
                              <div className="text-base text-gray-500">ID: {report.clientNumber}</div>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="py-4">
                          <div className="flex items-center space-x-2">
                            <Building className="w-5 h-5 text-gray-400" />
                            <span className="font-medium text-base">{report.facilityName}</span>
                          </div>
                        </TableCell>
                        <TableCell className="py-4">
                          <Badge className={`${getReportTypeColor(report.reportType)} border text-sm`}>
                            {report.reportType}
                          </Badge>
                        </TableCell>
                        <TableCell className="py-4">
                          <div className="flex items-center space-x-2">
                            <CalendarDays className="w-5 h-5 text-gray-400" />
                            <span className="text-base">
                              {report.createdAt 
                                ? new Date(report.createdAt).toLocaleDateString('en-US', {
                                    month: 'short',
                                    day: 'numeric',
                                    year: 'numeric'
                                  })
                                : "-"
                              }
                            </span>
                          </div>
                        </TableCell>
                        <TableCell className="py-4">
                          <div className="max-w-xs">
                            <p className={`text-base ${isExpanded ? '' : 'line-clamp-2'}`}>
                              {isExpanded ? report.description : truncateText(report.description, 100)}
                            </p>
                            {report.description.length > 100 && (
                              <button 
                                className="text-maternal-green-600 hover:text-maternal-green-700 text-sm font-medium mt-1"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  toggleRowExpansion(report.id);
                                }}
                              >
                                {isExpanded ? 'Show less' : 'Read more'}
                              </button>
                            )}
                          </div>
                        </TableCell>
                        <TableCell className="py-4">
                          <div className="flex flex-wrap gap-1">
                            {report.fileUrls && report.fileUrls.length > 0 ? (
                              report.fileUrls.slice(0, 2).map((url, index) => {
                                const fileInfo = getFileInfo(url);
                                return (
                                  <div
                                    key={index}
                                    className="flex items-center space-x-1 px-2 py-1 bg-gray-100 rounded-md text-sm"
                                    title={fileInfo.filename}
                                  >
                                    <span className="text-base">{fileInfo.fileType.icon}</span>
                                    <span className="text-gray-700 font-medium truncate max-w-20 text-sm">
                                      {fileInfo.filename}
                                    </span>
                                  </div>
                                );
                              })
                            ) : (
                              <span className="text-gray-400 text-base">No documents</span>
                            )}
                            {report.fileUrls && report.fileUrls.length > 2 && (
                              <div className="flex items-center px-2 py-1 bg-blue-100 rounded-md text-sm">
                                <span className="text-blue-700 font-medium">
                                  +{report.fileUrls.length - 2} more
                                </span>
                              </div>
                            )}
                          </div>
                        </TableCell>
                        <TableCell className="py-4">
                          {/* Action buttons moved to modal */}
                        </TableCell>
                      </TableRow>
                      
                      {/* Expanded Row Details */}
                      {isExpanded && (
                        <TableRow className="bg-gray-50/50">
                          <TableCell colSpan={8} className="py-6">
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                              <div className="space-y-3">
                                <div className="flex items-center space-x-2">
                                  <User className="w-4 h-4 text-gray-400" />
                                  <span className="text-sm font-medium text-gray-700">Reporter Details</span>
                                </div>
                                <div className="pl-6 space-y-2">
                                  <div className="text-sm">
                                    <span className="text-gray-500">Name:</span> 
                                    <span className="ml-2 font-medium">
                                      {report.isAnonymous ? "Anonymous" : report.clientName}
                                    </span>
                                  </div>
                                  <div className="text-sm">
                                    <span className="text-gray-500">ID:</span> 
                                    <span className="ml-2 font-medium">{report.clientNumber}</span>
                                  </div>
                                  {!report.isAnonymous && (
                                    <div className="text-sm">
                                      <span className="text-gray-500">Phone:</span> 
                                      <span className="ml-2 font-medium">{report.phoneNumber}</span>
                                    </div>
                                  )}
                                </div>
                              </div>

                              <div className="space-y-3">
                                <div className="flex items-center space-x-2">
                                  <Building className="w-4 h-4 text-gray-400" />
                                  <span className="text-sm font-medium text-gray-700">Facility Information</span>
                                </div>
                                <div className="pl-6 space-y-2">
                                  <div className="text-sm">
                                    <span className="text-gray-500">Facility:</span> 
                                    <span className="ml-2 font-medium">{report.facilityName}</span>
                                  </div>
                                  <div className="text-sm">
                                    <span className="text-gray-500">Report Type:</span> 
                                    <span className="ml-2">
                                      <Badge className={`${getReportTypeColor(report.reportType)} text-xs`}>
                                        {report.reportType}
                                      </Badge>
                                    </span>
                                  </div>
                                </div>
                              </div>

                              <div className="space-y-3">
                                <div className="flex items-center space-x-2">
                                  <FileText className="w-4 h-4 text-gray-400" />
                                  <span className="text-sm font-medium text-gray-700">Full Description</span>
                                </div>
                                <div className="pl-6">
                                  <p className="text-sm text-gray-700 leading-relaxed">
                                    {report.description}
                                  </p>
                                </div>
                              </div>

                              {/* Documents Section */}
                              <div className="space-y-3">
                                <div className="flex items-center space-x-2">
                                  <Paperclip className="w-4 h-4 text-gray-400" />
                                  <span className="text-sm font-medium text-gray-700">Attached Documents</span>
                                </div>
                                <div className="pl-6">
                                  {report.fileUrls && report.fileUrls.length > 0 ? (
                                    <div className="space-y-2">
                                      {report.fileUrls.map((url, index) => {
                                        const fileInfo = getFileInfo(url);
                                        return (
                                          <div
                                            key={index}
                                            className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200 hover:border-maternal-green-300 transition-colors"
                                          >
                                            <div className="flex items-center space-x-3">
                                              <div className={`text-2xl ${fileInfo.fileType.color}`}>
                                                {fileInfo.fileType.icon}
                                              </div>
                                              <div>
                                                <p className="text-sm font-medium text-gray-900">
                                                  {fileInfo.filename}
                                                </p>
                                                <p className="text-xs text-gray-500">
                                                  {fileInfo.fileType.label}
                                                </p>
                                              </div>
                                            </div>
                                            <div className="flex items-center space-x-2">
                                              <Button
                                                variant="ghost"
                                                size="sm"
                                                onClick={(e) => {
                                                  e.stopPropagation();
                                                  window.open(url, '_blank');
                                                }}
                                                className="h-8 px-2 text-maternal-green-600 hover:text-maternal-green-700 hover:bg-maternal-green-50"
                                              >
                                                <ExternalLink className="h-4 w-4 mr-1" />
                                                View
                                              </Button>
                                              <Button
                                                variant="ghost"
                                                size="sm"
                                                onClick={(e) => {
                                                  e.stopPropagation();
                                                  const link = document.createElement('a');
                                                  link.href = url;
                                                  link.download = fileInfo.filename;
                                                  link.click();
                                                }}
                                                className="h-8 px-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                                              >
                                                <Download className="h-4 w-4 mr-1" />
                                                Download
                                              </Button>
                                            </div>
                                          </div>
                                        );
                                      })}
                                    </div>
                                  ) : (
                                    <p className="text-sm text-gray-500 italic">No documents attached</p>
                                  )}
                                </div>
                              </div>

                              {/* Reply Section */}
                              {report.reply && (
                                <div className="space-y-3">
                                  <div className="flex items-center space-x-2">
                                    <MessageSquare className="w-4 h-4 text-green-600" />
                                    <span className="text-sm font-medium text-gray-700">Response Sent</span>
                                    <Badge className="bg-green-100 text-green-700 border-green-300 text-xs">
                                      {report.replySentAt ? new Date(report.replySentAt).toLocaleDateString() : 'Sent'}
                                    </Badge>
                                  </div>
                                  <div className="pl-6">
                                    <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                                      <p className="text-sm text-gray-700 leading-relaxed whitespace-pre-line">
                                        {report.reply}
                                      </p>
                                    </div>
                                  </div>
                                </div>
                              )}
                            </div>
                          </TableCell>
                  </TableRow>
                      )}
                    </React.Fragment>
                  );
                })}
              </TableBody>
            </Table>
            {filteredReports.length === 0 && (
              <div className="text-center py-12">
                <MessageSquare className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500 text-lg">No reports found</p>
                <p className="text-gray-400 text-sm">Try adjusting your search criteria</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Enhanced Report Details Modal */}
      <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center text-xl">
              <FileText className="h-5 w-5 mr-2 text-maternal-green-600" />
              Report Details
            </DialogTitle>
            <DialogDescription>
              Complete information about this whistleblower report
            </DialogDescription>
          </DialogHeader>
          {selectedReport && (
            <div className="space-y-6">
              {/* Reporter Information */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                  <User className="h-5 w-5 mr-2 text-maternal-green-600" />
                  Reporter Information
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-500">Name</label>
                    <p className="text-gray-900 font-medium">
                      {selectedReport.isAnonymous ? "Anonymous" : selectedReport.clientName}
                    </p>
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-500">Client ID</label>
                    <p className="text-gray-900 font-medium">{selectedReport.clientNumber}</p>
                  </div>
                  {!selectedReport.isAnonymous && (
                    <div className="space-y-2">
                      <label className="text-sm font-medium text-gray-500">Phone Number</label>
                      <p className="text-gray-900 font-medium flex items-center">
                        <Phone className="h-4 w-4 mr-2 text-gray-400" />
                        {selectedReport.phoneNumber}
                      </p>
                    </div>
                  )}
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-500">Anonymous Report</label>
                    <Badge className={selectedReport.isAnonymous ? "bg-green-100 text-green-800" : "bg-gray-100 text-gray-800"}>
                      {selectedReport.isAnonymous ? "Yes" : "No"}
                    </Badge>
                  </div>
                </div>
              </div>

              <Separator />

              {/* Facility Information */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                  <Building className="h-5 w-5 mr-2 text-maternal-green-600" />
                  Facility Information
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-500">Facility Name</label>
                    <p className="text-gray-900 font-medium">{selectedReport.facilityName}</p>
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-500">Report Type</label>
                    <Badge className={`${getReportTypeColor(selectedReport.reportType)}`}>
                      {selectedReport.reportType}
                    </Badge>
                  </div>
                </div>
              </div>

              <Separator />

              {/* Report Details */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                  <Calendar className="h-5 w-5 mr-2 text-maternal-green-600" />
                  Report Details
                </h3>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-500">Submission Date</label>
                    <p className="text-gray-900 font-medium flex items-center">
                      <CalendarDays className="h-4 w-4 mr-2 text-gray-400" />
                      {selectedReport.createdAt 
                        ? new Date(selectedReport.createdAt).toLocaleString('en-US', {
                            weekday: 'long',
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit'
                          })
                        : "-"
                      }
                    </p>
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-gray-500">Description</label>
                    <div className="bg-gray-50 rounded-lg p-4">
                      <p className="text-gray-900 leading-relaxed whitespace-pre-wrap">
                        {selectedReport.description}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <Separator />

              {/* Documents Section */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                  <Paperclip className="h-5 w-5 mr-2 text-maternal-green-600" />
                  Attached Documents
                </h3>
                <div className="space-y-3">
                  {selectedReport.fileUrls && selectedReport.fileUrls.length > 0 ? (
                    selectedReport.fileUrls.map((url, index) => {
                      const fileInfo = getFileInfo(url);
                      return (
                        <div
                          key={index}
                          className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-200"
                        >
                          <div className="flex items-center space-x-3">
                            <div className={`text-2xl ${fileInfo.fileType.color}`}>
                              {fileInfo.fileType.icon}
                            </div>
                            <div>
                              <p className="text-sm font-medium text-gray-900">
                                {fileInfo.filename}
                              </p>
                              <p className="text-xs text-gray-500">
                                {fileInfo.fileType.label}
                              </p>
                            </div>
                          </div>
                          <div className="flex items-center space-x-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => window.open(url, '_blank')}
                              className="text-maternal-green-600 border-maternal-green-200 hover:bg-maternal-green-50"
                            >
                              <ExternalLink className="h-4 w-4 mr-1" />
                              View
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => {
                                const link = document.createElement('a');
                                link.href = url;
                                link.download = fileInfo.filename;
                                link.click();
                              }}
                              className="text-blue-600 border-blue-200 hover:bg-blue-50"
                            >
                              <Download className="h-4 w-4 mr-1" />
                              Download
                            </Button>
                          </div>
                        </div>
                      );
                    })
                  ) : (
                    <div className="text-center py-6">
                      <Paperclip className="h-8 w-8 text-gray-300 mx-auto mb-2" />
                      <p className="text-gray-500 text-sm">No documents attached to this report</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
          {selectedReport && (
            <div className="flex justify-end gap-2 pt-4 border-t mt-6">
              {/* Reply button (if not replied) */}
              {!selectedReport.reply && (
                <Button
                  variant="outline"
                  onClick={() => handleReply(selectedReport)}
                  className="flex items-center gap-2"
                >
                  <MessageSquare className="h-5 w-5 text-blue-600" />
                  Reply
                </Button>
              )}
              {/* Mark as Read button (only if unread, and cannot unread) */}
              {!selectedReport.isRead && (
                <Button
                  variant="outline"
                  onClick={() => markAsRead(selectedReport.id)}
                  className="flex items-center gap-2"
                >
                  <Eye className="h-5 w-5 text-orange-600" />
                  Mark as Read
                </Button>
              )}
              <Button variant="default" onClick={() => setIsModalOpen(false)}>
                Close
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Reply Modal */}
      <Dialog open={isReplyModalOpen} onOpenChange={setIsReplyModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="flex items-center text-xl">
              <MessageSquare className="h-5 w-5 mr-2 text-blue-600" />
              Send Reply to User
            </DialogTitle>
            <DialogDescription>
              Send an automatic reply to acknowledge receipt of the report
            </DialogDescription>
          </DialogHeader>
          {replyingTo && (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="reply-message">Reply Message</Label>
                <Textarea
                  id="reply-message"
                  value={replyMessage}
                  onChange={(e) => setReplyMessage(e.target.value)}
                  className="min-h-[200px] resize-none"
                  placeholder="Enter your reply message..."
                />
              </div>
              <div className="flex justify-end space-x-2">
                <Button
                  variant="outline"
                  onClick={() => {
                    setIsReplyModalOpen(false);
                    setReplyingTo(null);
                    setReplyMessage("");
                  }}
                >
                  Cancel
                </Button>
                <Button
                  onClick={sendReply}
                  disabled={isSendingReply || !replyMessage.trim()}
                  className="bg-blue-600 hover:bg-blue-700"
                >
                  {isSendingReply ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                      Sending...
                    </>
                  ) : (
                    <>
                      <MessageSquare className="h-4 w-4 mr-2" />
                      Send Reply
                    </>
                  )}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
