"use client";

import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { AlertTriangle } from "lucide-react";

export default function NotFound() {
  const router = useRouter();
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50">
      <div className="flex flex-col items-center space-y-6 p-8 bg-white rounded-lg shadow-md">
        <AlertTriangle className="h-16 w-16 text-red-500" />
        <h1 className="text-4xl font-bold text-gray-900">404 - Page Not Found</h1>
        <p className="text-lg text-gray-600 text-center max-w-md">
          Sorry, the page you are looking for does not exist or has been moved.
        </p>
        <Button onClick={() => router.push("/")}>Go to Homepage</Button>
      </div>
    </div>
  );
} 