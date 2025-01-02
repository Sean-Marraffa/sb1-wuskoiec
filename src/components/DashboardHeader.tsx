import React from 'react';
import { BusinessSelector } from './BusinessSelector';

export function DashboardHeader() {
  return (
    <div className="bg-white shadow">
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="py-4">
          <BusinessSelector />
        </div>
      </div>
    </div>
  );
}