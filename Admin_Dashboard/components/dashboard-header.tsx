"use client"

import { Bell, Settings, LogOut, User, ChevronDown } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { useLocalAuth } from "@/hooks/use-auth";
import { useIsMobile } from "@/hooks/use-mobile";
import { useEffect, useState } from "react"
import { usePathname } from "next/navigation";

interface DashboardHeaderProps {
  onLogout: () => void
  onMenuToggle?: () => void
  isMobile: boolean
  isMobileMenuOpen?: boolean
}

export function DashboardHeader({ onLogout, onMenuToggle, isMobile, isMobileMenuOpen = false }: DashboardHeaderProps) {
  const [mounted, setMounted] = useState(false);
  const { role } = useLocalAuth();
  const [userData, setUserData] = useState({ name: '', email: '' });
  const isMobileMenu = useIsMobile();
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
    if (typeof window !== 'undefined') {
      const name = localStorage.getItem('adminName') || '';
      const email = localStorage.getItem('adminEmail') || '';
      setUserData({ name, email });
    }
  }, []);

  const firstLetter = userData.name ? userData.name.charAt(0).toUpperCase() : (role ? role.charAt(0).toUpperCase() : '?');

  if (!mounted) {
    return null;
  }

  // Remove the conditional that hides the header on /report
  // if (pathname === "/report") {
  //   return null;
  // }

  return (
    <header className="sticky top-0 z-50 w-full border-b border-gray-200 bg-white backdrop-blur supports-[backdrop-filter]:bg-white/90 shadow-sm">
      <div className="flex h-14 sm:h-16 items-center justify-between px-3 sm:px-4 lg:px-6 gap-2 sm:gap-4">
        {/* Mobile Hamburger Menu Toggle */}
        {isMobileMenu ? (
          <Button
            variant="ghost"
            size="icon"
            onClick={onMenuToggle}
            className="relative z-50 text-gray-800 hover:bg-gray-100 hover:text-gray-900 shrink-0"
            aria-label="Toggle navigation menu"
          >
            <div className="flex flex-col justify-center items-center w-5 h-5">
              <span
                className={`block h-0.5 w-5 bg-current transition-all duration-300 ease-out ${
                  isMobileMenuOpen ? "rotate-45 translate-y-1" : "-translate-y-1"
                }`}
              />
              <span
                className={`block h-0.5 w-5 bg-current transition-all duration-300 ease-out ${
                  isMobileMenuOpen ? "opacity-0" : "opacity-100"
                }`}
              />
              <span
                className={`block h-0.5 w-5 bg-current transition-all duration-300 ease-out ${
                  isMobileMenuOpen ? "-rotate-45 -translate-y-1" : "translate-y-1"
                }`}
              />
            </div>
          </Button>
        ) : (
          <SidebarTrigger className="text-green-800 hover:bg-green-100 hover:text-green-900 shrink-0" />
        )}

        {/* Logo/Title for Mobile */}
        {isMobile && (
          <div className="flex items-center gap-2 flex-1 min-w-0">
            <div className="flex h-7 w-7 sm:h-8 sm:w-8 items-center justify-center rounded-lg bg-gradient-to-br from-green-600 to-green-700 shrink-0">
              <span className="text-white text-xs sm:text-sm font-bold">H</span>
            </div>
            <h1 className="text-base sm:text-lg font-semibold text-gray-800 truncate">HealthyMother</h1>
          </div>
        )}

        {/* Desktop Title - Hidden on Mobile */}
        {!isMobile && (
          <div className="flex items-center gap-3 flex-1 min-w-0">
            <h1 className="text-base sm:text-lg lg:text-xl font-bold text-gray-900 truncate">
              App Admin Panel
            </h1>
          </div>
        )}

        {/* Desktop Search - Hidden on Mobile, shown on tablet+ */}
        {!isMobile && (
          <div className="hidden md:flex flex-1 max-w-md mx-4">
            <div className="relative w-full">{/* Search functionality can be added here */}</div>
          </div>
        )}

        {/* Right-aligned items container */}
        <div className="flex items-center gap-2 sm:gap-3 ml-auto shrink-0">
          {/* Notifications */}
          <Button
            variant="ghost"
            size="icon"
            className="relative text-gray-800 hover:bg-gray-100 hover:text-gray-900 h-9 w-9 sm:h-10 sm:w-10"
          >
            <Bell className="h-4 w-4 sm:h-5 sm:w-5" />
            <Badge className="absolute -top-1 -right-1 h-4 w-4 sm:h-5 sm:w-5 flex items-center justify-center p-0 text-[10px] sm:text-xs bg-red-500 text-white border-2 border-white">
              3
            </Badge>
          </Button>

          {/* User Menu */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button
                variant="ghost"
                className="flex items-center gap-1.5 sm:gap-2 px-1.5 sm:px-2 md:px-3 text-gray-800 hover:bg-gray-100 hover:text-gray-900 h-9 sm:h-10"
              >
                <Avatar className="h-7 w-7 sm:h-8 sm:w-8 ring-2 ring-gray-200 shrink-0">
                  <AvatarFallback className="bg-green-600 text-white font-bold flex items-center justify-center text-sm sm:text-base">
                    {firstLetter}
                  </AvatarFallback>
                </Avatar>
                {!isMobile && (
                  <div className="hidden md:flex flex-col items-start min-w-0">
                    <span className="text-xs sm:text-sm font-medium text-gray-900 truncate max-w-[120px] lg:max-w-none">
                      {userData.name || 'No Name'}
                    </span>
                    <span className="text-[10px] sm:text-xs text-gray-600 truncate max-w-[120px] lg:max-w-none">
                      {userData.email || role}
                    </span>
                  </div>
                )}
                <ChevronDown className="h-3 w-3 sm:h-4 sm:w-4 text-gray-600 shrink-0 hidden md:block" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56 bg-white border-gray-200 shadow-lg">
              <DropdownMenuLabel>
                <div className="flex flex-col space-y-1">
                  <span className="text-sm font-medium text-gray-900">{userData.name || 'No Name'}</span>
                  <span className="text-xs text-gray-600">{userData.email || role}</span>
                </div>
              </DropdownMenuLabel>
              <DropdownMenuSeparator className="bg-gray-200" />
              <DropdownMenuItem className="text-gray-700 hover:bg-gray-50 cursor-pointer">
                <User className="mr-2 h-4 w-4" />
                <span>Profile</span>
              </DropdownMenuItem>
              <DropdownMenuItem className="text-gray-700 hover:bg-gray-50 cursor-pointer">
                <Settings className="mr-2 h-4 w-4" />
                <span>Settings</span>
              </DropdownMenuItem>
              <DropdownMenuSeparator className="bg-gray-200" />
              <DropdownMenuItem onClick={onLogout} className="text-red-600 hover:bg-red-50 focus:bg-red-50 cursor-pointer">
                <LogOut className="mr-2 h-4 w-4" />
                <span>Sign out</span>
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  )
}

