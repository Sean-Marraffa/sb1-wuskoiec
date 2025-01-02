import React from 'react';
import { CheckCircle2 } from 'lucide-react';

const BENEFITS = [
  'Save time with automated booking management',
  'Reduce errors and double-bookings',
  'Increase revenue with better inventory utilization',
  'Improve customer satisfaction with professional service'
];

export function BenefitsSection() {
  return (
    <div className="py-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-2 lg:gap-16">
          <div className="relative h-64 overflow-hidden rounded-lg sm:h-80 lg:h-full">
            <img
              src="https://images.unsplash.com/photo-1600880292203-757bb62b4baf?auto=format&fit=crop&q=80"
              alt="Business dashboard"
              className="absolute inset-0 h-full w-full object-cover"
            />
          </div>

          <div className="lg:py-16">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
              Why choose BookingVibe?
            </h2>
            <div className="mt-8 space-y-4">
              {BENEFITS.map((benefit) => (
                <div key={benefit} className="flex items-start">
                  <CheckCircle2 className="h-6 w-6 text-green-500 flex-shrink-0" />
                  <span className="ml-3 text-gray-600">{benefit}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}