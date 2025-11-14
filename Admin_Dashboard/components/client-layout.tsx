"use client";

import { ReactNode, useState, useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useLocalAuth } from "../hooks/use-auth";
import { SidebarProvider } from "../components/ui/sidebar";
import { AppSidebar } from "../components/app-sidebar";
import { MobileNavigation } from "../components/mobile-navigation";
import { DashboardHeader } from "../components/dashboard-header";
import LoginPage from "../components/login-page";

export function ClientLayout({ children }: { children: ReactNode }) {
  const { role, loading, logout } = useLocalAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    setMounted(true);
    // Only check mobile after mount to avoid hydration mismatch
    if (typeof window !== 'undefined') {
      const checkMobile = () => {
        setIsMobile(window.innerWidth < 768);
      };
      checkMobile();
      window.addEventListener('resize', checkMobile);
      return () => window.removeEventListener('resize', checkMobile);
    }
  }, []);

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

  if (loading || !mounted) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center space-y-4">
          <div className="animate-spin rounded-full h-8 w-8 border-2 border-maternal-green-600 border-t-transparent"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!role) {
    return <LoginPage onLoginSuccess={() => window.location.reload()} />;
  }

  // Wait for mount to avoid hydration mismatch, then check mobile
  const shouldShowMobile = mounted && isMobile;

  if (shouldShowMobile) {
    return (
      <>
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
        <main className="p-3 sm:p-4 pt-20 sm:pt-24 pb-6">
          <div className="max-w-full mx-auto">
            {children}
          </div>
        </main>
      </>
    );
  }

  return (
    <SidebarProvider defaultOpen={true}>
      <div className="flex min-h-screen w-full bg-gray-50">
        <AppSidebar activeView={activeView} onViewChange={handleViewChange} patientCount={0} />
        <div className="flex-1 flex flex-col min-w-0">
          <DashboardHeader onLogout={handleLogout} isMobile={false} />
          <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-auto">
            <div className="w-full max-w-7xl mx-auto">
              {children}
            </div>
          </main>
        </div>
      </div>
    </SidebarProvider>
  );
}

