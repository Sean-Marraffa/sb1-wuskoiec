import React from 'react';
import { useNavigate } from 'react-router-dom';
import { LogOut } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

interface SignOutButtonProps {
  className?: string;
  isCollapsed?: boolean;
}

export function SignOutButton({ className = '', isCollapsed = false }: SignOutButtonProps) {
  const { signOut } = useAuth();
  const [isLoading, setIsLoading] = React.useState(false);

  const handleSignOut = async () => {
    try {
      setIsLoading(true);
      await signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button
      onClick={handleSignOut}
      disabled={isLoading}
      className={`flex items-center ${isCollapsed ? 'justify-center' : 'px-6'} py-4 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-50 ${className}`}
    >
      <LogOut className={`${isCollapsed ? '' : 'mr-3'} h-6 w-6 flex-shrink-0`} />
      {!isCollapsed && (isLoading ? 'Signing out...' : 'Sign out')}
    </button>
  );
}