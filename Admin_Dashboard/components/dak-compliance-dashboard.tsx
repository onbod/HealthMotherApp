import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { 
  AlertTriangle, 
  Calendar, 
  TrendingUp, 
  CheckCircle, 
  XCircle,
  Activity,
  Users,
  Target
} from 'lucide-react';

interface DAKIndicator {
  name: string;
  value: number;
  numerator: number;
  denominator: number;
  target: number;
  status: 'met' | 'not_met' | 'no_data';
}

interface DAKAlert {
  code: string;
  message: string;
  priority: 'high' | 'medium' | 'low';
  action: string;
  decisionPoint: string;
  visitId: string;
  visitNumber: number;
}

interface DAKQualityMetric {
  metric_name: string;
  metric_value: number;
  target_value: number;
  measurement_date: string;
  metric_type: string;
  description: string;
}

export function DAKComplianceDashboard() {
  const [indicators, setIndicators] = useState<DAKIndicator[]>([]);
  const [qualityMetrics, setQualityMetrics] = useState<DAKQualityMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDAKData();
  }, []);

  const loadDAKData = async () => {
    try {
      setLoading(true);
      
      // Load ANC indicators
      const indicatorsResponse = await fetch('/api/indicators/anc');
      if (indicatorsResponse.ok) {
        const indicatorsData = await indicatorsResponse.json();
        const formattedIndicators = indicatorsData.group?.map((item: any) => ({
          name: item.description,
          value: item.measureScore?.value || 0,
          numerator: item.numerator || 0,
          denominator: item.denominator || 0,
          target: item.target || 0,
          status: item.status || 'no_data'
        })) || [];
        setIndicators(formattedIndicators);
      }

      // Load quality metrics
      const metricsResponse = await fetch('/api/dak/quality-metrics');
      if (metricsResponse.ok) {
        const metricsData = await metricsResponse.json();
        setQualityMetrics(metricsData.qualityMetrics || []);
      }
    } catch (err) {
      setError('Failed to load DAK data');
      console.error('Error loading DAK data:', err);
    } finally {
      setLoading(false);
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'destructive';
      case 'medium': return 'default';
      case 'low': return 'secondary';
      default: return 'outline';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'met': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'not_met': return <XCircle className="h-4 w-4 text-red-500" />;
      default: return <Activity className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'met': return 'bg-green-100 text-green-800';
      case 'not_met': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <Alert variant="destructive">
        <AlertTriangle className="h-4 w-4" />
        <AlertDescription>{error}</AlertDescription>
      </Alert>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target className="h-5 w-5 text-blue-600" />
            DAK Compliance Dashboard
          </CardTitle>
          <p className="text-sm text-gray-600">
            Digital Adaptation Kit for Antenatal Care - WHO Standards Compliance
          </p>
        </CardHeader>
      </Card>

      {/* Key Metrics Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Indicators</p>
                <p className="text-2xl font-bold">{indicators.length}</p>
              </div>
              <Target className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Targets Met</p>
                <p className="text-2xl font-bold text-green-600">
                  {indicators.filter(i => i.status === 'met').length}
                </p>
              </div>
              <CheckCircle className="h-8 w-8 text-green-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Targets Not Met</p>
                <p className="text-2xl font-bold text-red-600">
                  {indicators.filter(i => i.status === 'not_met').length}
                </p>
              </div>
              <XCircle className="h-8 w-8 text-red-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Quality Metrics</p>
                <p className="text-2xl font-bold">{qualityMetrics.length}</p>
              </div>
              <TrendingUp className="h-8 w-8 text-purple-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* DAK Indicators */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5 text-green-600" />
            DAK ANC Indicators
          </CardTitle>
          <p className="text-sm text-gray-600">
            WHO Digital Adaptation Kit Antenatal Care Indicators
          </p>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {indicators.map((indicator, index) => (
              <div key={index} className="border rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-medium">{indicator.name}</h4>
                  <Badge className={getStatusColor(indicator.status)}>
                    {getStatusIcon(indicator.status)}
                    <span className="ml-1">{indicator.status}</span>
                  </Badge>
                </div>
                
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-3">
                  <div>
                    <p className="text-sm text-gray-600">Current Value</p>
                    <p className="font-semibold">{indicator.value.toFixed(1)}%</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Target</p>
                    <p className="font-semibold">{indicator.target}%</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Numerator</p>
                    <p className="font-semibold">{indicator.numerator}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Denominator</p>
                    <p className="font-semibold">{indicator.denominator}</p>
                  </div>
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Progress</span>
                    <span>{indicator.value.toFixed(1)}% / {indicator.target}%</span>
                  </div>
                  <Progress 
                    value={(indicator.value / indicator.target) * 100} 
                    className="h-2"
                  />
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Quality Metrics */}
      {qualityMetrics.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-purple-600" />
              Quality Improvement Metrics
            </CardTitle>
            <p className="text-sm text-gray-600">
              DAK-compliant quality metrics and outcomes
            </p>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {qualityMetrics.map((metric, index) => (
                <div key={index} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-medium">{metric.metric_name}</h4>
                    <Badge variant="outline">
                      {metric.metric_type}
                    </Badge>
                  </div>
                  
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-3">
                    <div>
                      <p className="text-sm text-gray-600">Current Value</p>
                      <p className="font-semibold">{metric.metric_value}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600">Target Value</p>
                      <p className="font-semibold">{metric.target_value}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600">Date</p>
                      <p className="font-semibold">
                        {new Date(metric.measurement_date).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  
                  {metric.description && (
                    <p className="text-sm text-gray-600">{metric.description}</p>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* DAK Decision Support Information */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-orange-600" />
            DAK Decision Support System
          </CardTitle>
          <p className="text-sm text-gray-600">
            Complete ANC decision tree implementation (ANC.DT.01-14)
          </p>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <h4 className="font-medium mb-2">Decision Points Implemented</h4>
              <ul className="space-y-1 text-sm">
                <li>• ANC.DT.01: Danger Signs Assessment</li>
                <li>• ANC.DT.02: Blood Pressure Assessment</li>
                <li>• ANC.DT.03: Proteinuria Testing</li>
                <li>• ANC.DT.04: Anemia Screening</li>
                <li>• ANC.DT.05: HIV Testing and Counseling</li>
                <li>• ANC.DT.06: Syphilis Screening</li>
                <li>• ANC.DT.07: Malaria Prevention</li>
                <li>• ANC.DT.08: Tetanus Immunization</li>
              </ul>
            </div>
            <div>
              <h4 className="font-medium mb-2">Additional Decision Points</h4>
              <ul className="space-y-1 text-sm">
                <li>• ANC.DT.09: Iron Supplementation</li>
                <li>• ANC.DT.10: Birth Preparedness</li>
                <li>• ANC.DT.11: Emergency Planning</li>
                <li>• ANC.DT.12: Postpartum Care Planning</li>
                <li>• ANC.DT.13: Family Planning Counseling</li>
                <li>• ANC.DT.14: Danger Sign Recognition</li>
              </ul>
            </div>
          </div>
          
          <div className="mt-4 pt-4 border-t">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-medium">Scheduling Guidelines</h4>
                <p className="text-sm text-gray-600">
                  ANC.S.01-05 scheduling logic implemented
                </p>
              </div>
              <Button variant="outline" size="sm">
                View Scheduling
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Refresh Button */}
      <div className="flex justify-center">
        <Button onClick={loadDAKData} variant="outline">
          Refresh DAK Data
        </Button>
      </div>
    </div>
  );
}
