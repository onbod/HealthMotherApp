"use client"

import React from "react"
import { useLocalAuth } from "../hooks/use-auth"
import { useRouter } from "next/navigation"

interface AuthLayoutProps {
  children: React.ReactNode
}

export default function AuthLayout({ children }: AuthLayoutProps) {
  const { role, loading } = useLocalAuth()
  const router = useRouter()

  // Show loading spinner while checking authentication
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-maternal-green-50 to-maternal-blue-50">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-maternal-green-600"></div>
      </div>
    )
  }

  // Redirect to dashboard if already authenticated
  if (role) {
    router.push("/")
    return null
  }

  // Show auth page if not authenticated
  return (
    <div className="min-h-screen bg-gradient-to-br from-maternal-green-50 to-maternal-blue-50 flex items-center justify-center p-4">
      {children}
    </div>
  )
} 