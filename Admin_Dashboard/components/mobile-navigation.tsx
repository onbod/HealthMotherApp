"use client"

import { BookOpen, Users, Clock, FileText, Bell, Heart, BarChart3, TrendingUp, X, Settings, MessageSquare } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import { useEffect, useState } from "react"

interface MobileNavigationProps {
  isOpen: boolean
  activeView: string
  onViewChange: (view: string) => void
  onClose: () => void
}

const menuItems = [
  {
    title: "Dashboard",
    icon: BarChart3,
    id: "dashboard",
    description: "Overview and key metrics",
  },
  {
    title: "Messages",
    icon: MessageSquare,
    id: "messages",
    description: "Patient messages and communications",
  },
  {
    title: "Patient Profiles",
    icon: Users,
    id: "patients",
    badge: "24",
    description: "Manage patient information",
  },
  {
    title: "Trimester Views",
    icon: Heart,
    id: "trimester-views",
    description: "Specialized trimester dashboards",
  },
  {
    title: "Health Education",
    icon: BookOpen,
    id: "health-education",
    description: "Health tips and nutrition guidance",
  },
  {
    title: "Appointment Requests",
    icon: Clock,
    id: "requests",
    badge: "3",
    description: "Pending appointment requests",
  },
  {
    title: "Analytics",
    icon: TrendingUp,
    id: "analytics",
    description: "Performance insights",
  },
  {
    title: "Notifications",
    icon: Bell,
    id: "notifications",
    badge: "12",
    description: "Messages and reminders",
  },
  {
    title: "Medical Records",
    icon: FileText,
    id: "records",
    description: "Patient medical data",
  },
]

export function MobileNavigation({ isOpen, activeView, onViewChange, onClose }: MobileNavigationProps) {
  // Handle escape key press
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        onClose()
      }
    }

    if (isOpen) {
      document.addEventListener("keydown", handleEscape)
      // Prevent body scroll when menu is open
      document.body.style.overflow = "hidden"
    } else {
      document.body.style.overflow = "unset"
    }

    return () => {
      document.removeEventListener("keydown", handleEscape)
      document.body.style.overflow = "unset"
    }
  }, [isOpen, onClose])

  const [role, setRole] = useState('admin');
  useEffect(() => {
    if (typeof window !== 'undefined') {
      setRole(localStorage.getItem('userRole') || 'admin');
    }
  }, []);

  const clinicianMenuItems = [
    {
      title: "Dashboard",
      icon: BarChart3,
      id: "dashboard",
      description: "Overview and key metrics",
    },
    {
      title: "Patients",
      icon: Users,
      id: "patients",
      badge: "24",
      description: "Manage patient information",
    },
    {
      title: "Referral",
      icon: FileText,
      id: "referral",
      description: "Patient referrals",
    },
  ];
  const menu = role === 'clinician' ? clinicianMenuItems : menuItems;

  const handleItemClick = (itemId: string) => {
    onViewChange(itemId)
    onClose()
  }

  return (
    <>
      {/* Backdrop with smooth fade */}
      <div
        className={cn(
          "fixed inset-0 bg-black/50 backdrop-blur-sm z-40 lg:hidden transition-opacity duration-300 ease-in-out",
          isOpen ? "opacity-100" : "opacity-0 pointer-events-none",
        )}
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Mobile Navigation Dropdown */}
      <div
        className={cn(
          "fixed top-0 left-0 right-0 bg-white shadow-2xl z-50 transform transition-all duration-300 ease-in-out lg:hidden",
          "border-b border-gray-200",
          isOpen ? "translate-y-0 opacity-100" : "-translate-y-full opacity-0",
        )}
        role="dialog"
        aria-modal="true"
        aria-label="Navigation menu"
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-100 bg-gradient-to-r from-blue-50 to-indigo-50">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-600 shadow-md">
              <Heart className="h-4 w-4 text-white" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-gray-900">PresTrack</h2>
              <p className="text-xs text-gray-600">Maternal Health Dashboard</p>
            </div>
          </div>
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="h-8 w-8 rounded-full hover:bg-white/80"
            aria-label="Close navigation menu"
          >
            <X className="h-4 w-4" />
          </Button>
        </div>

        {/* Navigation Items */}
        <div className="max-h-[calc(100vh-120px)] overflow-y-auto">
          <div className="p-4 space-y-2">
            {menu.map((item, index) => (
              <button
                key={item.id}
                onClick={() => handleItemClick(item.id)}
                className={cn(
                  "w-full flex items-center justify-between p-4 rounded-xl text-left transition-all duration-200",
                  "hover:bg-gray-50 active:bg-gray-100 active:scale-[0.98]",
                  "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                  activeView === item.id
                    ? "bg-blue-50 text-blue-700 border-2 border-blue-200 shadow-sm"
                    : "border-2 border-transparent hover:border-gray-200",
                )}
                style={{
                  animationDelay: `${index * 50}ms`,
                  animation: isOpen ? "slideInFromTop 0.3s ease-out forwards" : "none",
                }}
              >
                <div className="flex items-center space-x-4">
                  <div
                    className={cn(
                      "flex items-center justify-center w-10 h-10 rounded-lg transition-colors",
                      activeView === item.id ? "bg-blue-100 text-blue-600" : "bg-gray-100 text-gray-600",
                    )}
                  >
                    <item.icon className="h-5 w-5" />
                  </div>
                  <div className="flex-1">
                    <div className="font-semibold text-base">{item.title}</div>
                    <div className="text-sm text-gray-500">{item.description}</div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  {item.badge && (
                    <Badge variant={activeView === item.id ? "default" : "secondary"} className="text-xs font-medium">
                      {item.badge}
                    </Badge>
                  )}
                  <div
                    className={cn(
                      "w-2 h-2 rounded-full transition-all duration-200",
                      activeView === item.id ? "bg-blue-500 scale-100" : "bg-transparent scale-0",
                    )}
                  />
                </div>
              </button>
            ))}
          </div>

          {/* Settings Section */}
          <div className="border-t border-gray-100 p-4">
            <button
              className={cn(
                "w-full flex items-center space-x-4 p-4 rounded-xl text-left transition-all duration-200",
                "hover:bg-gray-50 active:bg-gray-100 active:scale-[0.98]",
                "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                "border-2 border-transparent hover:border-gray-200",
              )}
            >
              <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-gray-100 text-gray-600">
                <Settings className="h-5 w-5" />
              </div>
              <div className="flex-1">
                <div className="font-semibold text-base">Settings</div>
                <div className="text-sm text-gray-500">App preferences</div>
              </div>
            </button>
          </div>
        </div>

        {/* Footer */}
        <div className="border-t border-gray-100 p-4 bg-gray-50">
          <div className="text-center text-xs text-gray-500">
            <p>© 2024 PresTrack. All rights reserved.</p>
          </div>
        </div>
      </div>

      {/* CSS Animation Styles */}
      <style jsx>{`
        @keyframes slideInFromTop {
          from {
            opacity: 0;
            transform: translateY(-20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      `}</style>
    </>
  )
}
