"use client"

import React, { useState } from "react"
import { useRouter, usePathname } from "next/navigation"
import { useLocalAuth } from "../hooks/use-auth";
import { SidebarProvider } from "./ui/sidebar"
import { AppSidebar } from "./app-sidebar"
import { MobileNavigation } from "./mobile-navigation"
import { DashboardHeader } from "./dashboard-header"
import LoginPage from "./login-page"
import { useIsMobile } from "../hooks/use-mobile"

interface SharedLayoutProps {
  children: React.ReactNode
  activeView?: string
  patientCount?: number
}

export default function SharedLayout({ children, activeView: propActiveView, patientCount = 0 }: SharedLayoutProps) {
  const { role, loading, logout } = useLocalAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const isMobile = useIsMobile();

  // Determine active view from URL if not provided
  const activeView = propActiveView || (pathname === "/report" ? "report" : "dashboard");

  const handleLogout = () => {
    logout();
    router.push("/");
  };

  const handleViewChange = (view: string) => {
    if (view === "report") {
      router.push("/report");
    } else if (view === "referral") {
      router.push("/referral");
    } else if (view === "patients") {
      router.push("/patients");
    } else {
      router.push(`/?view=${view}`);
    }
    if (isMobile) {
      setIsMobileMenuOpen(false);
    }
  };

  // Show loading spinner while checking authentication
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center space-y-4">
          <div className="animate-spin rounded-full h-8 w-8 border-2 border-maternal-green-600 border-t-transparent"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  // Show login page if not authenticated
  if (!role) {
    return <LoginPage onLoginSuccess={() => window.location.reload()} />;
  }

  // Mobile Layout
  if (isMobile) {
    return (
      <div className="min-h-screen bg-gray-50">
        <DashboardHeader
          onLogout={handleLogout}
          onMenuToggle={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          isMobile={true}
          isMobileMenuOpen={isMobileMenuOpen}
        />
        <MobileNavigation
          isOpen={isMobileMenuOpen}
          activeView={activeView}
          onViewChange={handleViewChange}
          onClose={() => setIsMobileMenuOpen(false)}
        />
        <main className="p-2 pt-20">
          <div className="max-w-[98vw] mx-auto">
            {children}
          </div>
        </main>
      </div>
    );
  }

  // Desktop Layout
  return (
    <SidebarProvider defaultOpen={true}>
      <div className="flex min-h-screen w-full bg-gray-50">
        <AppSidebar activeView={activeView} onViewChange={handleViewChange} patientCount={patientCount} />
        <div className="flex-1 flex flex-col">
          <DashboardHeader onLogout={handleLogout} isMobile={false} />
          <main className="flex-1 p-2 overflow-auto">
            <div className="max-w-[98vw] mx-auto">
              {children}
            </div>
          </main>
        </div>
      </div>
    </SidebarProvider>
  );
} 