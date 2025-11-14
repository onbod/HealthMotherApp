"use client"

import * as React from "react"

// Breakpoint definitions
export const BREAKPOINTS = {
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  '2xl': 1536,
} as const

export type Breakpoint = keyof typeof BREAKPOINTS

/**
 * Hook to detect current breakpoint
 * Returns the current breakpoint name
 */
export function useBreakpoint() {
  const [breakpoint, setBreakpoint] = React.useState<Breakpoint>('sm')

  React.useEffect(() => {
    if (typeof window === 'undefined') return

    const updateBreakpoint = () => {
      const width = window.innerWidth
      if (width >= BREAKPOINTS['2xl']) {
        setBreakpoint('2xl')
      } else if (width >= BREAKPOINTS.xl) {
        setBreakpoint('xl')
      } else if (width >= BREAKPOINTS.lg) {
        setBreakpoint('lg')
      } else if (width >= BREAKPOINTS.md) {
        setBreakpoint('md')
      } else {
        setBreakpoint('sm')
      }
    }

    updateBreakpoint()
    window.addEventListener('resize', updateBreakpoint)
    return () => window.removeEventListener('resize', updateBreakpoint)
  }, [])

  return breakpoint
}

/**
 * Hook to check if screen is at or above a specific breakpoint
 */
export function useBreakpointAt(breakpoint: Breakpoint) {
  const [isAtBreakpoint, setIsAtBreakpoint] = React.useState<boolean>(false)

  React.useEffect(() => {
    if (typeof window === 'undefined') return

    const checkBreakpoint = () => {
      setIsAtBreakpoint(window.innerWidth >= BREAKPOINTS[breakpoint])
    }

    checkBreakpoint()
    window.addEventListener('resize', checkBreakpoint)
    return () => window.removeEventListener('resize', checkBreakpoint)
  }, [breakpoint])

  return isAtBreakpoint
}

/**
 * Hook to check if screen is below a specific breakpoint
 */
export function useBreakpointBelow(breakpoint: Breakpoint) {
  const [isBelowBreakpoint, setIsBelowBreakpoint] = React.useState<boolean>(true)

  React.useEffect(() => {
    if (typeof window === 'undefined') return

    const checkBreakpoint = () => {
      setIsBelowBreakpoint(window.innerWidth < BREAKPOINTS[breakpoint])
    }

    checkBreakpoint()
    window.addEventListener('resize', checkBreakpoint)
    return () => window.removeEventListener('resize', checkBreakpoint)
  }, [breakpoint])

  return isBelowBreakpoint
}

