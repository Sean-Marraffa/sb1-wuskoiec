import React from 'react';
import { useNavigate } from 'react-router-dom';

export function CTASection() {
  const navigate = useNavigate();
  
  return (
    <div className="bg-indigo-600">
      <div className="max-w-7xl mx-auto py-16 px-4 sm:px-6 lg:px-8">
        <div className="lg:flex lg:items-center lg:justify-between">
          <div>
            <h2 className="text-3xl font-bold tracking-tight text-white">
              Ready to transform your rental business?
            </h2>
            <p className="mt-3 text-lg text-indigo-100">
              Start your 30-day free trial today. No credit card required.
            </p>
          </div>
          <div className="mt-8 lg:mt-0 lg:flex-shrink-0">
            <button
              onClick={() => navigate('/onboarding')}
              className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50"
            >
              Get Started Free
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}