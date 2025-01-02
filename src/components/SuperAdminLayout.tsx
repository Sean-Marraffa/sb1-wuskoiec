import React from 'react';
import { Building2, Menu, X, Home, ChevronLeft } from 'lucide-react';
import { useSidebar } from '../contexts/SidebarContext';
import { SignOutButton } from './SignOutButton';

interface SuperAdminLayoutProps {
  children: React.ReactNode;
}

export function SuperAdminLayout({ children }: SuperAdminLayoutProps) {
  const [isSidebarOpen, setIsSidebarOpen] = React.useState(false);
  const { isCollapsed, toggleSidebar } = useSidebar();

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Sidebar */}
      <div className={`fixed inset-y-0 left-0 z-50 ${isCollapsed ? 'w-16' : 'w-64'} bg-white shadow-lg transform ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0 transition-all duration-200 ease-in-out`}>
        <div className="flex items-center justify-between h-16 px-6 border-b">
          <div className={`flex items-center ${isCollapsed ? 'justify-center w-full' : ''}`}>
            <Building2 className="h-8 w-8 text-indigo-600 flex-shrink-0" />
            <span className={`ml-2 text-xl font-bold transition-opacity duration-200 ${isCollapsed ? 'opacity-0 w-0' : 'opacity-100'}`}>
              Platform Admin
            </span>
          </div>
          {!isCollapsed && <button
            onClick={() => setIsSidebarOpen(false)}
            className="lg:hidden text-gray-500 hover:text-gray-600"
          >
            <X className="h-6 w-6" />
          </button>}
        </div>
        <nav className="px-4 py-4">
          <div className="space-y-1">
            <a 
              href="/platform" 
              className={`flex items-center px-2 py-2 text-sm font-medium text-gray-900 rounded-md hover:bg-gray-100 ${
                isCollapsed ? 'justify-center' : ''
              }`}
            >
              <Home className={`h-6 w-6 ${isCollapsed ? '' : 'mr-3'} flex-shrink-0`} />
              <span className={`transition-opacity duration-200 ${isCollapsed ? 'opacity-0 w-0' : 'opacity-100'}`}>
                Platform Dashboard
              </span>
            </a>
          </div>
        </nav>
        
        {/* Collapse button */}
        <button
          onClick={toggleSidebar}
          className="hidden lg:block absolute right-0 top-20 transform translate-x-1/2 bg-white rounded-full p-1.5 border border-gray-200 shadow-sm hover:bg-gray-50"
        >
          <ChevronLeft className={`h-4 w-4 text-gray-600 transition-transform duration-200 ${isCollapsed ? 'rotate-180' : ''}`} />
        </button>

        <div className="absolute bottom-0 w-full border-t border-gray-200">
          <SignOutButton className="w-full" isCollapsed={isCollapsed} />
        </div>
      </div>

      {/* Mobile header */}
      <div className="lg:hidden">
        <div className="flex items-center justify-between h-16 px-4 border-b bg-white">
          <button
            onClick={() => setIsSidebarOpen(true)}
            className="p-2 -ml-2 text-gray-500 hover:text-gray-600"
          >
            <Menu className="h-6 w-6" />
          </button>
          <div className="flex items-center">
            <Building2 className="h-8 w-8 text-indigo-600" />
            <span className="ml-2 text-xl font-bold">Platform Admin</span>
          </div>
          <div className="w-6" /> {/* Spacer for alignment */}
        </div>
      </div>

      {/* Main content */}
      <div className={`transition-all duration-200 ${isCollapsed ? 'lg:pl-16' : 'lg:pl-64'}`}>
        <main className="py-6 px-4 sm:px-6 lg:px-8">
          {children}
        </main>
      </div>

      {/* Mobile sidebar overlay */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}
    </div>
  );
}