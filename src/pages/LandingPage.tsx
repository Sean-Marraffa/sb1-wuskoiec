import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Building2, ArrowRight } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useIsSuperAdmin } from '../hooks/useIsSuperAdmin';
import { HeroCarousel } from '../components/landing/HeroCarousel';
import { AnimatedHeading } from '../components/landing/AnimatedHeading';
import { FeaturesSection } from '../components/landing/FeaturesSection';
import { BenefitsSection } from '../components/landing/BenefitsSection';
import { CTASection } from '../components/landing/CTASection';
import { Footer } from '../components/landing/Footer';

export function LandingPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { isSuperAdmin } = useIsSuperAdmin();
  const [currentBusinessType, setCurrentBusinessType] = useState('Rental Business');

  const getDashboardPath = () => {
    return isSuperAdmin ? '/platform' : '/dashboard';
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Navigation */}
      <nav className="fixed w-full bg-white/95 backdrop-blur-sm z-50 border-b border-gray-100 transition-all">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <Building2 className="h-8 w-8 text-indigo-600" />
              <span className="ml-2 text-xl font-bold text-gray-900">BookingVibe</span>
            </div>
            <div className="hidden md:flex items-center">
              {user ? (
                <button
                  onClick={() => navigate(getDashboardPath())}
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  {user.user_metadata?.full_name || user.email}
                </button>
              ) : (
                <>
                  <Link
                    to="/login"
                    className="text-gray-600 hover:text-gray-900 px-4 py-2 rounded-md text-sm font-medium"
                  >
                    Sign In
                  </Link>
                  <button
                    onClick={() => navigate('/onboarding')}
                    className="ml-4 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
                  >
                    Start Free Trial
                  </button>
                </>
              )}
            </div>
            <div className="md:hidden flex items-center">
              {user ? (
                <button
                  onClick={() => navigate(getDashboardPath())}
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Dashboard
                </button>
              ) : (
                <Link
                  to="/login"
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
                >
                  Sign In
                </Link>
              )}
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section with Carousel */}
      <div className="relative pt-16">
        <HeroCarousel onSlideChange={setCurrentBusinessType} />
        <div className="absolute inset-0 flex items-center justify-center z-10 px-4">
          <div className="text-center">
            <AnimatedHeading currentSlide={0} businessType={currentBusinessType} />
            <p className="text-lg sm:text-xl text-white/90 mb-8 max-w-2xl mx-auto px-4 hidden sm:block">
              Manage bookings, inventory, and payments with ease. The all-in-one platform designed for modern rental businesses.
            </p>
            <p className="text-lg text-white/90 mb-8 max-w-2xl mx-auto px-4 sm:hidden">
              The all-in-one platform for modern rental businesses.
            </p>
            <div className="flex flex-col items-center space-y-4">
              <button
                onClick={() => navigate('/onboarding')}
                className="inline-flex items-center px-6 sm:px-8 py-3 sm:py-4 border border-transparent text-base sm:text-lg font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 w-full sm:w-auto justify-center"
              >
                Start Free Trial <ArrowRight className="ml-2 h-5 w-5" />
              </button>
              <p className="text-white/75 text-xs sm:text-sm px-4">30-day free trial • No credit card required</p>
            </div>
          </div>
        </div>
      </div>

      <FeaturesSection />
      <BenefitsSection />
      <CTASection />
      <Footer />
    </div>
  );
}