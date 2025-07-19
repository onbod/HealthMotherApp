"use client";

import "./globals.css";
import { ReactNode, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useLocalAuth } from "../hooks/use-auth";
import { SidebarProvider } from "../components/ui/sidebar";
import { AppSidebar } from "../components/app-sidebar";
import { MobileNavigation } from "../components/mobile-navigation";
import { DashboardHeader } from "../components/dashboard-header";
import LoginPage from "../components/login-page";
import { useIsMobile } from "../hooks/use-mobile";

export default function RootLayout({ children }: { children: ReactNode }) {
  const { role, loading, logout } = useLocalAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const isMobile = useIsMobile();

  // Determine active view from URL if not provided
  const activeView = pathname === "/report" ? "report" : 
                    pathname === "/patients" ? "patients" :
                    pathname === "/referral" ? "referral" :
                    pathname === "/" ? "dashboard" : "dashboard";

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

  if (loading) {
    return (
      <html lang="en">
        <body>
          <div className="min-h-screen flex items-center justify-center bg-gray-50">
            <div className="flex flex-col items-center space-y-4">
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-maternal-green-600 border-t-transparent"></div>
              <p className="text-gray-600">Loading...</p>
            </div>
          </div>
        </body>
      </html>
    );
  }

  if (!role) {
    return (
      <html lang="en">
        <body>
          <LoginPage onLoginSuccess={() => window.location.reload()} />
        </body>
      </html>
    );
  }

  if (isMobile) {
    return (
      <html lang="en">
        <body>
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
        </body>
      </html>
    );
  }

  return (
    <html lang="en">
      <body>
        <SidebarProvider defaultOpen={true}>
          <div className="flex min-h-screen w-full bg-gray-50">
            <AppSidebar activeView={activeView} onViewChange={handleViewChange} patientCount={0} />
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
      </body>
    </html>
  );
}
