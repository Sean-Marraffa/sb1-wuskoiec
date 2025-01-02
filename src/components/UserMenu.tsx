import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { LogOut, Settings, User } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

interface UserMenuProps {
  isCollapsed?: boolean;
  className?: string;
}

export function UserMenu({ isCollapsed = false, className = '' }: UserMenuProps) {
  const [isOpen, setIsOpen] = useState(false);
  const { user, signOut } = useAuth();
  const fullName = user?.user_metadata?.full_name || user?.email || 'User';

  return (
    <div className="relative">
      <button
        onClick={() => !isCollapsed && setIsOpen(!isOpen)}
        className={`flex items-center w-full ${isCollapsed ? 'justify-center' : 'px-6'} py-4 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-50 ${className}`}
      >
        <User className={`${isCollapsed ? '' : 'mr-3'} h-6 w-6 flex-shrink-0`} />
        {!isCollapsed && (
          <span className="truncate">{fullName}</span>
        )}
      </button>

      {isOpen && !isCollapsed && (
        <>
          <div
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute bottom-full left-0 mb-1 w-56 rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 z-20">
            <div className="py-1">
              <div className="px-4 py-2 text-sm text-gray-900 border-b border-gray-100">
                {fullName}
              </div>
              <Link
                to="/profile"
                className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                onClick={() => setIsOpen(false)}
              >
                <Settings className="mr-3 h-4 w-4" />
                User Settings
              </Link>
              <button
                onClick={signOut}
                className="flex w-full items-center px-4 py-2 text-sm text-red-700 hover:bg-gray-100"
              >
                <LogOut className="mr-3 h-4 w-4" />
                Sign Out
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}