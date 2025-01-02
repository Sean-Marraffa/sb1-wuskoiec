import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { SidebarProvider } from './contexts/SidebarContext';
import { AuthLayout } from './components/AuthLayout';
import { OnboardingPage } from './pages/OnboardingPage';
import { LandingPage } from './pages/LandingPage';
import { AppLayout } from './components/AppLayout';
import { LoginForm } from './components/LoginForm';
import { Dashboard } from './pages/Dashboard';
import { Settings } from './pages/Settings';
import { Inventory } from './pages/Inventory';
import { Customers } from './pages/Customers';
import { UserProfile } from './pages/UserProfile';
import { Reservations } from './pages/Reservations';
import { BusinessProfileSetup } from './pages/BusinessProfileSetup';
import { PlatformDashboard } from './pages/PlatformDashboard';
import { ProtectedRoute } from './components/ProtectedRoute';
import { SuperAdminRoute } from './components/SuperAdminRoute';
import { BillingPage } from './pages/BillingPage';
import { AcceptInvitePage } from './pages/AcceptInvitePage';

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <SidebarProvider>
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route
              path="/onboarding"
              element={<OnboardingPage />}
            />
            <Route
              path="/accept-invite"
              element={<AcceptInvitePage />}
            />
            <Route
              path="/login"
              element={
                <AuthLayout>
                  <LoginForm />
                </AuthLayout>
              }
            />
            <Route
              path="/setup-business"
              element={
                <ProtectedRoute>
                  <BusinessProfileSetup />
                </ProtectedRoute>
              }
            />
            <Route
              path="/billing"
              element={
                <ProtectedRoute>
                  <BillingPage />
                </ProtectedRoute>
              }
            />
            
            {/* Protected routes with persistent layout */}
            <Route
              element={
                <ProtectedRoute>
                  <AppLayout />
                </ProtectedRoute>
              }
            >
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/inventory" element={<Inventory />} />
              <Route path="/reservations" element={<Reservations />} />
              <Route path="/customers" element={<Customers />} />
              <Route path="/profile" element={<UserProfile />} />
              <Route path="/settings" element={<Settings />} />
              <Route
                path="/platform"
                element={
                  <SuperAdminRoute>
                    <PlatformDashboard />
                  </SuperAdminRoute>
                }
              />
            </Route>
          </Routes>
        </SidebarProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}