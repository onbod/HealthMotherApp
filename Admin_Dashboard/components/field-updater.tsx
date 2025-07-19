"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Loader2, CheckCircle, AlertCircle } from "lucide-react"

export function FieldUpdater() {
  const [collectionName, setCollectionName] = useState("ancRecords")
  const [oldFieldName, setOldFieldName] = useState("")
  const [newFieldName, setNewFieldName] = useState("")
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<{ success: boolean; updatedCount?: number; error?: string } | null>(null)

  const handleUpdate = async () => {
    if (!collectionName || !oldFieldName || !newFieldName) {
      setResult({ success: false, error: "Please fill in all fields" })
      return
    }

    setLoading(true)
    setResult(null)

    try {
      // Replace any Firestore usage with static dummy data or useState.
      // For now, we'll simulate an update.
      console.log(`Simulating update for collection: ${collectionName}, old field: ${oldFieldName}, new field: ${newFieldName}`);
      setResult({ success: true, updatedCount: 1 }); // Simulate one document updated
    } catch (error) {
      setResult({ success: false, error: error instanceof Error ? error.message : "Unknown error" })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <AlertCircle className="h-5 w-5" />
          Update Field Names
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="collection">Collection Name</Label>
          <Input
            id="collection"
            value={collectionName}
            onChange={(e) => setCollectionName(e.target.value)}
            placeholder="e.g., ancRecords"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="oldField">Old Field Name</Label>
          <Input
            id="oldField"
            value={oldFieldName}
            onChange={(e) => setOldFieldName(e.target.value)}
            placeholder="e.g., oldFieldName"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="newField">New Field Name</Label>
          <Input
            id="newField"
            value={newFieldName}
            onChange={(e) => setNewFieldName(e.target.value)}
            placeholder="e.g., newFieldName"
          />
        </div>

        <Button 
          onClick={handleUpdate} 
          disabled={loading || !collectionName || !oldFieldName || !newFieldName}
          className="w-full"
        >
          {loading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Updating...
            </>
          ) : (
            "Update Field Names"
          )}
        </Button>

        {result && (
          <Alert variant={result.success ? "default" : "destructive"}>
            {result.success ? (
              <CheckCircle className="h-4 w-4" />
            ) : (
              <AlertCircle className="h-4 w-4" />
            )}
            <AlertDescription>
              {result.success 
                ? `Successfully updated ${result.updatedCount} documents`
                : result.error
              }
            </AlertDescription>
          </Alert>
        )}
      </CardContent>
    </Card>
  )
} 