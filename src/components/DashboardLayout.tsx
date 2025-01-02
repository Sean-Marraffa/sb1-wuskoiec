import React, { useState } from 'react';
import { Building2, Menu, X, Home, Calendar, Settings, Users, ChevronLeft, Package } from 'lucide-react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useIsSuperAdmin } from '../hooks/useIsSuperAdmin';
import { useSidebar } from '../contexts/SidebarContext';
import { UserMenu } from './UserMenu';
import { BusinessSelector } from './BusinessSelector';

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const { isSuperAdmin } = useIsSuperAdmin();
  const { isCollapsed, toggleSidebar } = useSidebar();
  const location = useLocation();
  const navigate = useNavigate();

  const isActive = (path: string) => location.pathname === path;

  const navItems = isSuperAdmin ? [
    { path: '/platform', icon: Building2, label: 'Platform Dashboard' }
  ] : [
    { path: '/dashboard', icon: Home, label: 'Dashboard' },
    { path: '/reservations', icon: Calendar, label: 'Reservations' },
    { path: '/inventory', icon: Package, label: 'Inventory' },
    { path: '/customers', icon: Users, label: 'Customers' },
    { path: '/settings', icon: Settings, label: 'Settings' }
  ];

  const NavLink = ({ to, icon: Icon, children }: { to: string; icon: typeof Home; children: React.ReactNode }) => (
    <Link
      to={to}
      className={`flex items-center p-2 text-sm font-medium rounded-md transition-colors ${
        isCollapsed ? 'justify-center' : ''
      } ${
        isActive(to)
          ? 'text-gray-900 bg-gray-100'
          : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
      }`}
    >
      <Icon className={`h-6 w-6 flex-shrink-0 ${isCollapsed ? '' : 'mr-3'}`} />
      <span className={`transition-all duration-200 ${isCollapsed ? 'hidden' : 'block'}`}>
        {children}
      </span>
    </Link>
  );

  const getActionButton = () => {
    const path = location.pathname;
    switch (path) {
      case '/dashboard':
        return (
          <button
            onClick={() => navigate('/reservations?action=new')}
            className="p-2 text-white bg-indigo-600 rounded-full hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
          </button>
        );
      case '/reservations':
        return (
          <button
            onClick={() => navigate('/reservations?action=new')}
            className="p-2 text-white bg-indigo-600 rounded-full hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
          </button>
        );
      case '/inventory':
        return (
          <button
            onClick={() => navigate('/inventory?action=new')}
            className="p-2 text-white bg-indigo-600 rounded-full hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
          </button>
        );
      case '/customers':
        return (
          <button
            onClick={() => navigate('/customers?action=new')}
            className="p-2 text-white bg-indigo-600 rounded-full hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
          </button>
        );
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Sidebar */}
      <div
        className={`fixed inset-y-0 left-0 z-50 ${
          isCollapsed ? 'w-16' : 'w-64'
        } bg-white shadow-lg transform ${
          isSidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } lg:translate-x-0 transition-all duration-200 ease-in-out`}
      >
        <div className="flex items-center justify-between h-16 px-6 border-b">
          <div className={`flex items-center ${isCollapsed ? 'justify-center w-full' : ''}`}>
            <Building2 className="h-8 w-8 text-indigo-600 flex-shrink-0" />
            <span
              className={`ml-2 text-xl font-bold transition-all duration-200 ${
                isCollapsed ? 'opacity-0 w-0' : 'opacity-100'
              }`}
            >
              BookingVibe
            </span>
          </div>
          {!isCollapsed && (
            <button
              onClick={() => setIsSidebarOpen(false)}
              className="lg:hidden text-gray-500 hover:text-gray-600"
            >
              <X className="h-6 w-6" />
            </button>
          )}
        </div>

        <nav className="px-4 py-4">
          <div className="space-y-1">
            {!isSuperAdmin && <div>
              <BusinessSelector />
            </div>}
            {navItems.map(item => (
              <NavLink key={item.path} to={item.path} icon={item.icon}>
                {item.label}
              </NavLink>
            ))}
          </div>
        </nav>

        {/* Collapse button */}
        <button
          onClick={toggleSidebar}
          className="hidden lg:block absolute right-0 top-20 transform translate-x-1/2 bg-white rounded-full p-1.5 border border-gray-200 shadow-sm hover:bg-gray-50"
        >
          <ChevronLeft
            className={`h-4 w-4 text-gray-600 transition-transform duration-200 ${
              isCollapsed ? 'rotate-180' : ''
            }`}
          />
        </button>

        <div className="absolute bottom-0 w-full border-t border-gray-200">
          <UserMenu className="w-full" isCollapsed={isCollapsed} />
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
          <div className="flex items-center flex-1 justify-center">
            <Building2 className="h-8 w-8 text-indigo-600" />
            <span className="ml-2 text-xl font-bold">BookingVibe</span>
          </div>
          {getActionButton()}
        </div>
      </div>

      {/* Main content */}
      <div
        className={`transition-all duration-200 ${isCollapsed ? 'lg:pl-16' : 'lg:pl-64'}`}
      >
        <main className="py-6 px-4 sm:px-6 lg:px-8">{children}</main>
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