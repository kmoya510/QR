import React, { useState, useRef, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Camera, Save, XCircle, RotateCcw, QrCode, Barcode } from 'lucide-react';

const BarcodeScanner = () => {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  
  const [scannerState, setScannerState] = useState({
    isScanning: false,
    scanMode: 'qr', // 'qr' or 'barcode'
    error: '',
    scannedData: null,
    loading: false
  });

  const [notification, setNotification] = useState({
    show: false,
    type: 'info', // 'info', 'success', 'error'
    message: ''
  });

  const [formData, setFormData] = useState({
    responseId: '',
    formId: '',
    answers: []
  });

  const [cameraPermission, setCameraPermission] = useState('prompt');

  useEffect(() => {
    checkCameraPermission();
    return () => {
      stopScanner();
    };
  }, []);

  // Auto-hide notifications after 3 seconds
  useEffect(() => {
    if (notification.show) {
      const timer = setTimeout(() => {
        setNotification(prev => ({ ...prev, show: false }));
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [notification.show]);

  const showNotification = (type, message) => {
    setNotification({
      show: true,
      type,
      message
    });
  };

  const checkCameraPermission = async () => {
    try {
      const result = await navigator.permissions.query({ name: 'camera' });
      setCameraPermission(result.state);
      
      result.addEventListener('change', () => {
        setCameraPermission(result.state);
      });
    } catch (err) {
      console.error('Camera permission check failed:', err);
    }
  };

  const startScanner = async () => {
    setScannerState(prev => ({ ...prev, loading: true, error: '' }));
    
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { 
          facingMode: 'environment',
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      });
      
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        setScannerState(prev => ({ 
          ...prev, 
          isScanning: true, 
          loading: false 
        }));
        
        startCodeDetection();
      }
    } catch (err) {
      setScannerState(prev => ({
        ...prev,
        error: 'Failed to access camera. Please check permissions.',
        loading: false
      }));
      showNotification('error', 'Unable to access camera. Please check your permissions.');
    }
  };

  const stopScanner = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    setScannerState(prev => ({ ...prev, isScanning: false }));
  };

  const startCodeDetection = async () => {
    try {
      // Here we would implement actual QR/barcode detection
      console.log('Starting code detection...');
    } catch (err) {
      setScannerState(prev => ({
        ...prev,
        error: 'Failed to initialize code scanner'
      }));
    }
  };

  const toggleScanMode = () => {
    setScannerState(prev => ({
      ...prev,
      scanMode: prev.scanMode === 'qr' ? 'barcode' : 'qr'
    }));
  };

  const submitToMSForms = async (data) => {
    setScannerState(prev => ({ ...prev, loading: true }));
    
    try {
      const response = await fetch('YOUR_AZURE_FUNCTION_URL', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN'
        },
        body: JSON.stringify({
          formId: formData.formId,
          responseId: formData.responseId,
          answers: [{
            questionId: 'YOUR_QUESTION_ID',
            value: data
          }]
        })
      });

      if (!response.ok) {
        throw new Error('Failed to submit to Microsoft Forms');
      }

      showNotification('success', 'Data successfully submitted to Microsoft Forms');
    } catch (err) {
      showNotification('error', err.message);
    } finally {
      setScannerState(prev => ({ ...prev, loading: false }));
    }
  };

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle className="flex justify-between items-center">
          <span>{scannerState.scanMode === 'qr' ? 'QR Code Scanner' : 'Barcode Scanner'}</span>
          <Button variant="outline" size="sm" onClick={toggleScanMode}>
            {scannerState.scanMode === 'qr' ? 
              <QrCode className="h-4 w-4 mr-2" /> : 
              <Barcode className="h-4 w-4 mr-2" />
            }
            Switch to {scannerState.scanMode === 'qr' ? 'Barcode' : 'QR'}
          </Button>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* Notification Alert */}
          {notification.show && (
            <Alert variant={notification.type === 'error' ? 'destructive' : 'default'}>
              <AlertDescription>{notification.message}</AlertDescription>
            </Alert>
          )}

          {/* Camera View */}
          <div className="relative rounded-lg overflow-hidden">
            {scannerState.isScanning ? (
              <>
                <video 
                  ref={videoRef} 
                  autoPlay 
                  playsInline 
                  className="w-full h-64 bg-black rounded-lg"
                />
                <Button
                  variant="destructive"
                  className="absolute top-2 right-2"
                  onClick={stopScanner}
                >
                  <XCircle className="h-4 w-4 mr-2" />
                  Stop
                </Button>
              </>
            ) : (
              <Button 
                className="w-full h-64"
                onClick={startScanner}
                disabled={scannerState.loading || cameraPermission === 'denied'}
              >
                {scannerState.loading ? (
                  <RotateCcw className="h-4 w-4 animate-spin mr-2" />
                ) : (
                  <>
                    <Camera className="h-4 w-4 mr-2" />
                    Start {scannerState.scanMode === 'qr' ? 'QR' : 'Barcode'} Scanner
                  </>
                )}
              </Button>
            )}
          </div>

          {/* Error Display */}
          {scannerState.error && (
            <Alert variant="destructive">
              <AlertDescription>{scannerState.error}</AlertDescription>
            </Alert>
          )}

          {/* Scanned Data Display */}
          {scannerState.scannedData && (
            <div className="space-y-4">
              <div>
                <Label>Scanned {scannerState.scanMode === 'qr' ? 'QR Code' : 'Barcode'}</Label>
                <Input
                  value={scannerState.scannedData}
                  readOnly
                  className="mt-1"
                />
              </div>
              
              <Button 
                className="w-full"
                onClick={() => submitToMSForms(scannerState.scannedData)}
                disabled={scannerState.loading}
              >
                {scannerState.loading ? (
                  <RotateCcw className="h-4 w-4 animate-spin mr-2" />
                ) : (
                  <Save className="h-4 w-4 mr-2" />
                )}
                Submit to Microsoft Forms
              </Button>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default BarcodeScanner;
