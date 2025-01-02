import React, { useState } from 'react';
import { ChevronDown, Building2 } from 'lucide-react';
import { useBusinessProfile } from '../hooks/useBusinessProfile';
import { useDefaultBusiness } from '../hooks/useDefaultBusiness';
import { useIsSuperAdmin } from '../hooks/useIsSuperAdmin';
import { useSidebar } from '../contexts/SidebarContext';

export function BusinessSelector() {
  const [isOpen, setIsOpen] = useState(false);
  const { businessProfile, loading: profileLoading } = useBusinessProfile();
  const { defaultBusiness, setDefaultBusiness, loading: defaultLoading } = useDefaultBusiness();
  const { isSuperAdmin } = useIsSuperAdmin();
  const { isCollapsed } = useSidebar();

  const loading = profileLoading || defaultLoading;

  // Don't render for super admins
  if (isSuperAdmin) {
    return null;
  }

  const handleSelect = async (businessId: string) => {
    await setDefaultBusiness(businessId);
    setIsOpen(false);
  };

  if (loading) {
    return (
      <div className="flex items-center px-2 py-2">
        <div className="h-8 w-full bg-gray-100 animate-pulse rounded" />
      </div>
    );
  }

  return (
    <div className="relative">
      <button
        onClick={() => !isCollapsed && setIsOpen(!isOpen)}
        className="flex items-center w-full p-2 text-sm font-medium text-gray-900 rounded-md hover:bg-gray-100 focus:outline-none"
      >
        <div className="flex items-center min-w-0 w-full">
          <Building2 className="h-6 w-6 text-gray-900 flex-shrink-0" />
          <span className={`ml-3 flex-1 truncate transition-all duration-200 ${isCollapsed ? 'w-0 opacity-0' : 'w-auto opacity-100'}`}>
            {businessProfile?.name || 'Select Business'}
          </span>
          {!isCollapsed && <ChevronDown className="h-4 w-4 text-gray-500 flex-shrink-0 ml-2" />}
        </div>
      </button>

      {isOpen && !isCollapsed && (
        <>
          <div
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute left-0 mt-2 w-full rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-20">
            <div className="py-1">
              {businessProfile && (
                <button
                  className={`block w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 text-left ${
                    defaultBusiness?.id === businessProfile.id ? 'bg-gray-50' : ''
                  }`}
                  onClick={() => handleSelect(businessProfile.id)}
                >
                  {businessProfile.name}
                </button>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}