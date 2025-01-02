import React, { useState, useEffect } from 'react';
import { Edit2, Save } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useBusinessProfile } from '../../hooks/useBusinessProfile';

interface StatusSetting {
  key: 'draft' | 'reserved' | 'in_use' | 'closed';
  defaultLabel: string;
  description: string;
}

const DEFAULT_STATUSES: StatusSetting[] = [
  { key: 'draft', defaultLabel: 'Proposal', description: 'Start building the order' },
  { key: 'reserved', defaultLabel: 'Reserved', description: 'Secure the booking' },
  { key: 'in_use', defaultLabel: 'Checked Out', description: 'The rental is happening' },
  { key: 'closed', defaultLabel: 'Checked In', description: 'Finish the process' }
];

export function ReservationStatusSettings() {
  const { businessProfile } = useBusinessProfile();
  const [statusLabels, setStatusLabels] = useState<Record<string, string>>({});
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (businessProfile) {
      fetchStatusLabels();
    }
  }, [businessProfile]);

  async function fetchStatusLabels() {
    try {
      const { data, error } = await supabase
        .from('reservation_status_settings')
        .select('status_key, label')
        .eq('business_id', businessProfile?.id);

      if (error) throw error;

      const labels: Record<string, string> = {};
      data?.forEach(item => {
        labels[item.status_key] = item.label;
      });
      
      // Set default values for any missing statuses
      DEFAULT_STATUSES.forEach(status => {
        if (!labels[status.key]) {
          labels[status.key] = status.defaultLabel;
        }
      });

      setStatusLabels(labels);
    } catch (err) {
      console.error('Error fetching status labels:', err);
    } finally {
      setLoading(false);
    }
  }

  const handleSave = async () => {
    try {
      const updates = DEFAULT_STATUSES.map(status => ({
        business_id: businessProfile?.id,
        status_key: status.key,
        label: statusLabels[status.key]
      }));

      const { error } = await supabase
        .from('reservation_status_settings')
        .upsert(updates, {
          onConflict: 'business_id,status_key'
        });

      if (error) throw error;
      setIsEditing(false);
    } catch (err) {
      console.error('Error saving status labels:', err);
      alert('Failed to save status labels');
    }
  };

  if (loading) {
    return <div className="animate-pulse space-y-4">
      <div className="h-8 bg-gray-200 rounded w-1/4" />
      <div className="space-y-2">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="h-12 bg-gray-200 rounded" />
        ))}
      </div>
    </div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h3 className="text-lg font-medium text-gray-900">Reservation Statuses</h3>
        <button
          onClick={() => isEditing ? handleSave() : setIsEditing(true)}
          className="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          {isEditing ? (
            <>
              <Save className="h-4 w-4 mr-1.5" />
              Save Changes
            </>
          ) : (
            <>
              <Edit2 className="h-4 w-4 mr-1.5" />
              Edit Labels
            </>
          )}
        </button>
      </div>

      <div className="space-y-4">
        {DEFAULT_STATUSES.map((status) => (
          <div key={status.key} className="flex items-start space-x-4 bg-gray-50 p-4 rounded-lg">
            <div className="flex-1">
              <div className="flex items-center space-x-2">
                <input
                  type="text"
                  value={statusLabels[status.key]}
                  onChange={(e) => setStatusLabels(prev => ({
                    ...prev,
                    [status.key]: e.target.value
                  }))}
                  disabled={!isEditing}
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 disabled:bg-transparent disabled:border-transparent"
                />
              </div>
              <p className="mt-1 text-sm text-gray-500">{status.description}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}