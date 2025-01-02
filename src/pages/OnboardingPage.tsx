import React from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { Building2, ChevronLeft } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { SignOutButton } from '../components/SignOutButton';
import { SignUpForm } from '../components/SignUpForm';
import { BusinessProfileForm } from '../components/forms/BusinessProfileForm';
import { PlanSelectionForm } from '../components/forms/PlanSelectionForm';

const steps = [
  { id: 'signup', title: 'Create Account', description: 'Set up your login credentials' },
  { id: 'business', title: 'Business Profile', description: 'Tell us about your business' },
  { id: 'plan', title: 'Select Plan', description: 'Choose the right plan for you' }
];

export function OnboardingPage() {
  const { user } = useAuth();
  const navigate = useNavigate();

  // Determine current step based on user metadata
  const getCurrentStep = () => {
    if (!user) return 'signup';
    if (user.user_metadata?.needs_business_profile) return 'business';
    if (!user.user_metadata?.has_billing) return 'plan';
    return 'complete';
  };

  const currentStep = getCurrentStep();

  // Redirect to dashboard if onboarding is complete
  if (currentStep === 'complete') {
    return <Navigate to="/dashboard" />;
  }

  const currentStepIndex = steps.findIndex(step => step.id === currentStep);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center">
              <Building2 className="h-8 w-8 text-indigo-600" />
              <span className="ml-2 text-xl font-bold">BookingVibe</span>
            </div>
            <SignOutButton />
          </div>
        </div>
      </header>

      {/* Progress Steps */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
        <nav aria-label="Progress">
          <ol className="space-y-4 md:flex md:space-y-0 md:space-x-8">
            {steps.map((step, index) => (
              <li key={step.id} className="md:flex-1">
                <div className={`group pl-4 py-2 flex flex-col border-l-4 ${
                  index < currentStepIndex ? 'border-indigo-600'
                  : index === currentStepIndex ? 'border-indigo-600'
                  : 'border-gray-200'
                } md:pl-0 md:pt-4 md:pb-0 md:border-l-0 md:border-t-4`}>
                  <span className={`text-xs font-semibold tracking-wide uppercase ${
                    index < currentStepIndex ? 'text-indigo-600'
                    : index === currentStepIndex ? 'text-indigo-600'
                    : 'text-gray-500'
                  }`}>
                    Step {index + 1}
                  </span>
                  <span className="text-sm font-medium">
                    {step.title}
                  </span>
                </div>
              </li>
            ))}
          </ol>
        </nav>

        {/* Back Button */}
        {currentStep !== 'signup' && (
          <button
            onClick={() => navigate('/')}
            className="mt-8 inline-flex items-center text-sm text-gray-500 hover:text-gray-700"
          >
            <ChevronLeft className="h-4 w-4 mr-1" />
            Back to home
          </button>
        )}

        {/* Step Content */}
        <div className="mt-8 bg-white shadow rounded-lg p-6">
          <h2 className="text-2xl font-bold text-gray-900 mb-8">
            {steps[currentStepIndex].title}
          </h2>
          
          {currentStep === 'signup' && <SignUpForm />}
          {currentStep === 'business' && <BusinessProfileForm />}
          {currentStep === 'plan' && <PlanSelectionForm />}
        </div>
      </div>
    </div>
  );
}