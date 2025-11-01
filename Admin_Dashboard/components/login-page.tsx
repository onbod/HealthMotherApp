"use client"

import React, { useState } from "react"
import { Eye, EyeOff, Heart, Lock, Mail, AlertCircle } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { getApiUrl } from "@/lib/config"

interface LoginPageProps {
  onLoginSuccess: () => void
}

interface FormErrors {
  email?: string
  password?: string
  general?: string
}

const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess }) => {
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    rememberMe: false,
  })

  const [errors, setErrors] = useState<FormErrors>({})
  const [isLoading, setIsLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  // Remove role state and handleRoleChange

  // Remove role state and handleRoleChange

  // Remove: const auth = getAuth(app)

  const validateEmail = (email: string): boolean => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {}
    if (!formData.email) newErrors.email = "Email address is required"
    else if (!validateEmail(formData.email)) newErrors.email = "Please enter a valid email"
    if (!formData.password) newErrors.password = "Password is required"
    else if (formData.password.length < 8) newErrors.password = "Password must be at least 8 characters"
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleInputChange = (field: keyof typeof formData, value: string | boolean) => {
    setFormData((prev) => ({ ...prev, [field]: value }))
    if (errors[field as keyof FormErrors]) {
      setErrors((prev) => ({ ...prev, [field]: undefined }))
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;
    setIsLoading(true);
    setErrors({});
    try {
      const res = await fetch(getApiUrl('/admin/login'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: formData.email, password: formData.password })
      });
      const data = await res.json();
      if (res.ok && data.token) {
        if (typeof window !== 'undefined') {
          localStorage.setItem('adminToken', data.token);
          localStorage.setItem('adminName', data.name || '');
          localStorage.setItem('adminEmail', data.email || '');
          localStorage.setItem('userRole', 'admin');
          onLoginSuccess && onLoginSuccess();
          window.location.reload();
        }
        setIsLoading(false);
        return;
      } else {
        setErrors({ general: data.error || 'Invalid email or password.' });
        setIsLoading(false);
        return;
      }
    } catch (err) {
      setErrors({ general: 'Network error. Please try again.' });
      setIsLoading(false);
      return;
    }
  }

  const adminName = typeof window !== 'undefined' ? localStorage.getItem('adminName') : '';
  const adminEmail = typeof window !== 'undefined' ? localStorage.getItem('adminEmail') : '';
  const firstLetter = adminName ? adminName.charAt(0).toUpperCase() : '';

  return (
    <div className="flex items-center justify-center h-screen overflow-hidden">
      {/* Left Column - Image */}
      <div className="hidden md:flex lg:w-1/2 xl:w-3/5 relative order-2 lg:order-1 h-screen">
        <div className="absolute inset-0 bg-gradient-to-br from-maternal-green-500/20 to-maternal-blue-500/20 z-10" />
        <img
          src="/maternal-portrait.jpeg"
          alt="Maternal Health - Expecting Mother"
          className="w-full h-full object-cover"
          loading="eager"
          crossOrigin="anonymous"
        />
        <div className="absolute bottom-0 left-0 right-0 p-8 z-20 bg-gradient-to-t from-black/60 to-transparent">
          <div className="text-white">
            <h2 className="text-3xl font-bold mb-2">Nurturing Every Journey</h2>
            <p className="text-lg opacity-90">
              Celebrating the beauty and strength of motherhood with compassionate, expert care at every step.
            </p>
          </div>
        </div>
      </div>

      {/* Right Column - Login Form */}
      <div className="w-full md:w-full lg:w-1/2 xl:w-2/5 flex items-center justify-center p-4 sm:p-6 lg:p-8 xl:p-12 bg-gradient-to-br from-maternal-blue-50 to-maternal-green-50 order-1 lg:order-2">
        <div className="w-full max-w-sm sm:max-w-md lg:max-w-lg space-y-6 sm:space-y-8">
          {/* Header */}
          <div className="text-center">
            <div className="flex justify-center mb-4 sm:mb-6">
              <div className="flex h-12 w-12 sm:h-16 sm:w-16 items-center justify-center rounded-full bg-gradient-to-r from-maternal-green-500 to-maternal-blue-500 shadow-lg">
                <Heart className="h-6 w-6 sm:h-8 sm:w-8 text-white" />
              </div>
            </div>
            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-maternal-brown-700 mb-2">HealthyMother</h1>
            <p className="text-maternal-brown-600 text-base sm:text-lg">Secure Healthcare Dashboard</p>
          </div>

          {/* Mobile Image Display */}
          <div className="md:hidden relative mb-6 sm:mb-8">
            <Card className="overflow-hidden border-maternal-green-200">
              <div className="relative h-40 sm:h-48">
                <div className="absolute inset-0 bg-gradient-to-r from-maternal-green-500/10 to-maternal-blue-500/10 z-10" />
                <img
                  src="/maternal-portrait.jpeg"
                  alt="Maternal Health"
                  className="w-full h-full object-cover"
                  loading="eager"
                  crossOrigin="anonymous"
                />
                <div className="absolute inset-0 flex items-center justify-center z-20">
                  <div className="text-center text-white bg-black/40 p-4 rounded-lg backdrop-blur-sm">
                    <h3 className="font-semibold text-lg">Celebrating Motherhood</h3>
                    <p className="text-sm opacity-90">Expert care, beautiful journey</p>
                  </div>
                </div>
              </div>
            </Card>
          </div>

          {/* Login Card */}
          <Card className="shadow-xl border-maternal-green-200 bg-white/90 backdrop-blur-sm">
            <CardHeader className="space-y-1 pb-4 sm:pb-6 px-4 sm:px-6">
              <CardTitle className="text-xl sm:text-2xl font-bold text-center text-maternal-brown-800">
                Welcome Back
              </CardTitle>
              <CardDescription className="text-center text-maternal-brown-600 text-sm sm:text-base">
                Sign in to access your maternal health dashboard
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 sm:space-y-6 px-4 sm:px-6">
              <form onSubmit={handleSubmit} className="space-y-5">
                {/* Remove Role Selector */}
                {errors.general && (
                  <Alert variant="destructive" className="border-red-200 bg-red-50">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription className="text-red-800">{errors.general}</AlertDescription>
                  </Alert>
                )}

                <div className="space-y-2">
                  <Label htmlFor="email" className="text-sm font-medium text-maternal-brown-700">
                    Email Address
                  </Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-maternal-brown-500" />
                    <Input
                      id="email"
                      type="email"
                      placeholder="ibrahimswaray430@gmail.com"
                      value={formData.email}
                      onChange={(e) => handleInputChange("email", e.target.value)}
                      className={`pl-10 h-11 sm:h-12 text-base bg-white/70 border-maternal-green-300 focus:border-maternal-green-500 focus:ring-2 focus:ring-maternal-green-500/20 ${
                        errors.email ? "border-red-500 focus:border-red-500 focus:ring-red-500/20" : ""
                      }`}
                      disabled={isLoading}
                    />
                  </div>
                  {errors.email && <p className="text-sm text-red-600 mt-1">{errors.email}</p>}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="password" className="text-sm font-medium text-maternal-brown-700">
                    Password
                  </Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-maternal-brown-500" />
                    <Input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="Enter your password"
                      value={formData.password}
                      onChange={(e) => handleInputChange("password", e.target.value)}
                      className={`pl-10 pr-12 h-12 bg-white/70 border-maternal-green-300 focus:border-maternal-green-500 focus:ring-2 focus:ring-maternal-green-500/20 ${
                        errors.password ? "border-red-500 focus:border-red-500 focus:ring-red-500/20" : ""
                      }`}
                      disabled={isLoading}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-maternal-brown-500 hover:text-maternal-brown-700 transition-colors"
                      disabled={isLoading}
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {errors.password && <p className="text-sm text-red-600 mt-1">{errors.password}</p>}
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="remember"
                      checked={formData.rememberMe}
                      onCheckedChange={(checked) => handleInputChange("rememberMe", checked as boolean)}
                      disabled={isLoading}
                      className="border-maternal-green-400 data-[state=checked]:bg-maternal-green-500 data-[state=checked]:border-maternal-green-500"
                    />
                    <Label htmlFor="remember" className="text-sm text-maternal-brown-600 cursor-pointer">
                      Remember me for 30 days
                    </Label>
                  </div>
                  <Button
                    variant="link"
                    className="text-sm text-maternal-blue-600 hover:text-maternal-blue-700 p-0 h-auto"
                  >
                    Forgot password?
                  </Button>
                </div>

                <Button
                  type="submit"
                  className="w-full h-11 sm:h-12 text-base sm:text-lg bg-gradient-to-r from-maternal-green-500 to-maternal-blue-500 hover:from-maternal-green-600 hover:to-maternal-blue-600 text-white font-medium transition-all duration-200 shadow-lg hover:shadow-xl"
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <div className="flex items-center space-x-2">
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      <span>Signing in...</span>
                    </div>
                  ) : (
                    "Sign In"
                  )}
                </Button>
              </form>

              {/* Demo Credentials */}
              <div className="pt-4 sm:pt-6 border-t border-maternal-green-200">
                <div className="text-center">
                  <p className="text-xs sm:text-sm text-maternal-brown-600 mb-2 sm:mb-3">
                    Demo Credentials for Testing:
                  </p>
                  <div className="bg-gradient-to-r from-maternal-green-50 to-maternal-blue-50 p-3 sm:p-4 rounded-lg border border-maternal-green-200">
                    <div className="font-mono text-xs sm:text-sm text-maternal-brown-700 space-y-1">
                      <div>
                        <span className="font-medium text-maternal-brown-600">APP Admin:</span> ibrahimswaray430@gmail.com / dauda2019
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Footer */}
          <div className="text-center">
            <p className="text-sm text-maternal-brown-500">© 2024 HealthyMother. All rights reserved.</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default LoginPage
