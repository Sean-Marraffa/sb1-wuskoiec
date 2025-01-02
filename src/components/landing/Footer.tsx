import React from 'react';
import { Building2 } from 'lucide-react';

export function Footer() {
  return (
    <footer className="bg-gray-50">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <Building2 className="h-8 w-8 text-indigo-600" />
            <span className="ml-2 text-xl font-bold text-gray-900">BookingVibe</span>
          </div>
          <p className="text-gray-500 text-sm">
            © {new Date().getFullYear()} BookingVibe. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}