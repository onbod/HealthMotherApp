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

  return (
    <header className="sticky top-0 z-50 w-full border-b border-white-300 bg-white backdrop-blur supports-[backdrop-filter]:bg-white-200/90">
      <div className="flex h-16 items-center justify-between px-4 gap-4">
        {/* Mobile Hamburger Menu Toggle */}
        {isMobileMenu ? (
          <Button
            variant="ghost"
            size="icon"
            onClick={onMenuToggle}
            className="relative z-50 text-white-800 hover:bg-white-300 hover:text-white-900"
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
          <SidebarTrigger className="text-green-800 hover:bg-green-300 hover:text-green-900" />
        )}

        {/* Logo/Title for Mobile */}
        {isMobile && (
          <div className="flex items-center gap-2 flex-1">
            <div className="flex h-6 w-6 items-center justify-center rounded-lg bg-gradient-to-br from-white-600 to-white-700">
              <span className="text-white-800 text-xs font-bold">H</span>
            </div>
            <h1 className="text-lg font-semibold text-white-800">HealthyMother</h1>
          </div>
        )}

        {/* Desktop Search - Hidden on Mobile */}
        {!isMobile && (
          <div className="flex-1 max-w-md">
            <div className="relative">{/* Search functionality can be added here */}</div>
          </div>
        )}

        {/* Date and Time - Hidden on Mobile */}
        {!isMobile && (
          <div className="hidden md:flex flex-col items-end text-sm text-white-600">
            {/* Date/time display can be added here */}
          </div>
        )}
        <h1 className="text-black ml-4 font-bold">App Admin Panel</h1>
        {/* Right-aligned items container */}
        <div className="flex items-center gap-3 ml-auto">
          {/* Notifications */}
          <Button
            variant="ghost"
            size="icon"
            className="relative text-white-800 hover:bg-white-300 hover:text-white-900"
          >
            <Bell className="h-5 w-5" />
            <Badge className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 text-xs bg-white-600 text-white-800 border-white-700">
              3
            </Badge>
          </Button>

          {/* User Menu */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button
                variant="ghost"
                className="flex items-center gap-2 px-2 sm:px-3 text-white-800 hover:bg-white-300 hover:text-white-900"
              >
                <Avatar className="h-8 w-8 ring-2 ring-white-500">
                  <AvatarFallback className="bg-maternal-green-500 text-white font-bold flex items-center justify-center text-xl">
                    {firstLetter}
                  </AvatarFallback>
                </Avatar>
                {!isMobile && (
                  <div className="hidden sm:flex flex-col items-start">
                    <span className="text-sm font-medium text-green-800">{userData.name || 'No Name'}</span>
                    <span className="text-xs text-white-600">{userData.email || role}</span>
                  </div>
                )}
                <ChevronDown className="h-4 w-4 text-white-700" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56 bg-white border-white-300">
              <DropdownMenuLabel>
                <div className="flex flex-col space-y-1">
                  <span className="text-sm font-medium text-green-800">{userData.name || 'No Name'}</span>
                  <span className="text-xs text-green-600">{userData.email || role}</span>
                </div>
              </DropdownMenuLabel>
              <DropdownMenuSeparator className="bg-white-200" />
              <DropdownMenuItem className="text-white-700 hover:bg-white-50">
                <User className="mr-2 h-4 w-4" />
                <span>Profile</span>
              </DropdownMenuItem>
              <DropdownMenuItem className="text-white-700 hover:bg-white-50">
                <Settings className="mr-2 h-4 w-4" />
                <span>Settings</span>
              </DropdownMenuItem>
              <DropdownMenuSeparator className="bg-white-200" />
              <DropdownMenuItem onClick={onLogout} className="text-red-600 hover:bg-red-50 focus:bg-red-50">
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

