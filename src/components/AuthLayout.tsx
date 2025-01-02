import React from 'react';
import { Link } from 'react-router-dom';
import { Building2 } from 'lucide-react';

interface AuthLayoutProps {
  children: React.ReactNode;
}

export function AuthLayout({ children }: AuthLayoutProps) {
  return (
    <div className="min-h-screen flex">
      {/* Left side - Image */}
      <div className="hidden lg:flex lg:w-1/2 relative bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-500">
        <img
          className="absolute inset-0 w-full h-full object-cover mix-blend-overlay opacity-40"
          src="https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&q=80"
          alt="Equipment rental venue"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/30 to-black/10" />
        <div className="relative w-full flex flex-col justify-between p-12">
          <Link to="/" className="flex items-center text-white hover:text-white/90">
            <Building2 className="h-8 w-8" />
            <span className="ml-2 text-xl font-bold">BookingVibe</span>
          </Link>
          <div className="text-white">
            <h2 className="text-5xl font-bold mb-6">Effortless Rentals</h2>
            <p className="text-xl text-white/90">Manage bookings, inventory, and payments with ease.</p>
          </div>
        </div>
      </div>

      {/* Right side - Auth Form */}
      <div className="flex-1 flex flex-col justify-center px-4 sm:px-6 lg:px-20 xl:px-24 bg-white">
        <div className="w-full max-w-sm mx-auto">
          <Link to="/" className="lg:hidden flex items-center justify-center mb-8 hover:opacity-90">
            <Building2 className="h-10 w-10 text-indigo-600" />
            <span className="ml-2 text-2xl font-bold text-gray-900">BookingVibe</span>
          </Link>
          {children}
        </div>
      </div>
    </div>
  );
}