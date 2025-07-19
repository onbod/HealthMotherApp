"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { useIsMobile } from "@/hooks/use-mobile"

interface ResponsiveNavigationProps {
  children: React.ReactNode
  mobileNavigation: React.ReactNode
  desktopNavigation: React.ReactNode
}

export function ResponsiveNavigation({ children, mobileNavigation, desktopNavigation }: ResponsiveNavigationProps) {
  const isMobile = useIsMobile()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return null
  }

  return (
    <>
      {isMobile ? mobileNavigation : desktopNavigation}
      {children}
    </>
  )
}
