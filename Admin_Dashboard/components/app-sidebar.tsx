"use client"

import { BookOpen, Users, Clock, FileText, Settings, Bell, Heart, BarChart3, TrendingUp, AlertTriangle, Home, Activity, MessageSquare } from "lucide-react"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import { Badge } from "@/components/ui/badge"
import { useEffect, useState } from "react"

interface AppSidebarProps {
  activeView: string
  onViewChange: (view: string) => void
  patientCount: number
}

export function AppSidebar({ activeView, onViewChange, patientCount }: AppSidebarProps) {
  const [notificationCount, setNotificationCount] = useState<number | null>(null);
  const [reportCount, setReportCount] = useState<number>(0);
  const [unreadReportCount, setUnreadReportCount] = useState<number>(0);
  const [unreadMessagesCount, setUnreadMessagesCount] = useState<number>(0);
  const [role, setRole] = useState('admin');

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setRole(localStorage.getItem('userRole') || 'admin');
    }
  }, []);

  useEffect(() => {
    // Real-time updates for unread messages count
    // const unsubscribe = db ? onSnapshot(collection(db, "chats"), (snapshot) => {
    //   let totalUnread = 0;
    //   snapshot.forEach(docSnap => {
    //     const data = docSnap.data();
    //     totalUnread += data.unreadCount || 0;
    //   });
    //   setUnreadMessagesCount(totalUnread);
    // }) : undefined;

    // Other counts (notifications, reports) can remain as getDocs
    // const fetchCounts = async () => {
    //   try {
    //     // Fetch notification count
    //     const notificationSnapshot = await getDocs(collection(db, "notifications"));
    //     setNotificationCount(notificationSnapshot.size);

    //     // Fetch report counts
    //     const reportSnapshot = await getDocs(collection(db, "report"));
    //     const reports = reportSnapshot.docs.map(doc => doc.data());
    //     setReportCount(reports.length);
    //     setUnreadReportCount(reports.filter((report: any) => !report.isRead).length);
    //   } catch (error) {
    //     console.error("Error fetching counts:", error);
    //     setNotificationCount(0);
    //     setReportCount(0);
    //     setUnreadReportCount(0);
    //   }
    // };
    // fetchCounts();
    // return () => { if (unsubscribe) unsubscribe(); };
  }, []);

  const menuItems = role === 'clinician' ? [
    {
      title: "Dashboard",
      icon: Home,
      id: "dashboard",
    },
    {
      title: "Patients",
      icon: Users,
      id: "patients",
      badge: patientCount.toString(),
    },
    {
      title: "Referral",
      icon: FileText,
      id: "referral",
    },
  ] : [
    {
      title: "Dashboard",
      icon: Home,
      id: "dashboard",
    },
    {
      title: "Messages",
      icon: MessageSquare,
      id: "messages",
      badge: unreadMessagesCount.toString(),
    },
    {
      title: "Patients",
      icon: Users,
      id: "patients",
      badge: patientCount.toString(),
    },
    // {
    //   title: "Trimester Views",
    //   icon: Activity,
    //   id: "trimester-views",
    // },
    {
      title: "Health Education",
      icon: BookOpen,
      id: "health-education",
    },
    // {
    //   title: "Appointment Requests",
    //   icon: Clock,
    //   id: "requests",
    //   badge: "3",
    // },
    // {
    //   title: "Analytics",
    //   icon: TrendingUp,
    //   id: "analytics",
    // },
    {
      title: "Notifications",
      icon: Bell,
      id: "notifications",
      badge: notificationCount !== null ? notificationCount.toString() : undefined,
    },
    {
      title: "Reports",
      icon: AlertTriangle,
      id: "report",
      badge: unreadReportCount.toString(),
    },
    {
      title: "Medical Records",
      icon: FileText,
      id: "records",
    },
  ];

  return (
    <Sidebar className="border-r border-gray-200 bg-white">
      <SidebarHeader className="p-4 bg-maternal-green-600">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20">
            <Heart className="h-5 w-5 text-white" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white">HealthyMother</h2>
            <p className="text-xs text-white/80">Dashboard</p>
          </div>
        </div>
      </SidebarHeader>

      <SidebarContent className="px-2 py-4">
        <SidebarGroup>
          <SidebarGroupLabel className="px-3 text-xs font-medium text-gray-500 uppercase tracking-wider mb-2">
            Navigation
          </SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu className="space-y-1">
              {menuItems.map((item) => (
                <SidebarMenuItem key={item.id}>
                  <SidebarMenuButton
                    onClick={() => onViewChange(item.id)}
                    isActive={activeView === item.id}
                    className={`
                      group w-full justify-start px-3 py-2.5 rounded-lg
                      ${activeView === item.id
                        ? `bg-blue-600 text-white`
                        : `text-black hover:bg-blue-50`
                      }
                    `}
                  >
                    <div className="flex items-center gap-3 w-full">
                      <item.icon className={`h-4 w-4 ${activeView === item.id ? 'text-white' : 'text-black'}`} />
                      <span className={`font-medium text-sm ${activeView === item.id ? 'text-white' : 'text-black'}`}>{item.title}</span>
                      {item.badge !== undefined && (
                        <Badge
                          className={`
                            ml-auto px-2 py-0.5 text-xs font-medium rounded-full
                            ${activeView === item.id
                              ? 'bg-white/20 text-white'
                              : 'bg-blue-500 text-white'
                            }
                          `}
                        >
                          {item.badge}
                        </Badge>
                      )}
                    </div>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="p-3 border-t border-gray-200">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton className="
              w-full justify-start px-3 py-2.5 rounded-lg
              text-gray-600 hover:text-gray-800 hover:bg-gray-100
            ">
              <div className="flex items-center gap-3 w-full">
                <div className="flex items-center justify-center w-7 h-7 rounded-md bg-gray-500 text-white">
                  <Settings className="h-4 w-4" />
                </div>
                <span className="font-medium text-sm">Settings</span>
              </div>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  )
}
