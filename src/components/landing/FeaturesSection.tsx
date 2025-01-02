import React from 'react';
import { Calendar, Package, Users } from 'lucide-react';
import { FeatureCard } from './FeatureCard';

const FEATURES = [
  {
    icon: Calendar,
    title: 'Smart Booking Management',
    description: 'Effortlessly manage reservations, handle scheduling conflicts, and track availability in real-time.'
  },
  {
    icon: Package,
    title: 'Inventory Control',
    description: 'Keep track of your equipment and assets with detailed inventory management and maintenance scheduling.'
  },
  {
    icon: Users,
    title: 'Customer Management',
    description: 'Build lasting relationships with integrated customer profiles, communication, and booking history.'
  }
];

export function FeaturesSection() {
  return (
    <div className="py-24 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Everything you need to run your rental business
          </h2>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            Powerful features designed to help you grow and manage your business efficiently.
            Try everything free for 30 days.
          </p>
        </div>

        <div className="mt-20 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((feature) => (
            <FeatureCard key={feature.title} {...feature} />
          ))}
        </div>
        <div className="mt-12 text-center">
          <button
            onClick={() => navigate('/onboarding')}
            className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
          >
            Start Free Trial
          </button>
          <p className="mt-3 text-sm text-gray-500">No credit card required</p>
        </div>
      </div>
    </div>
  );
}