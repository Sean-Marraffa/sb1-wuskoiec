// Update the Business interface import
import type { Business } from '../types/business';
import { BusinessStatusBadge } from './BusinessStatusBadge';

// ... existing imports ...

export function BusinessTable({ businesses, loading, onDelete }: BusinessTableProps) {
  return (
    <>
      <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
        <h3 className="text-lg leading-6 font-medium text-gray-900">
          All Businesses
        </h3>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Business
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Type
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Contact
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Location
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Plan
              </th>
              {/* ... other columns ... */}
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-6 py-4">
                  <div className="animate-pulse flex space-x-4">
                    <div className="flex-1 space-y-4 py-1">
                      <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                    </div>
                  </div>
                </td>
              </tr>
            ) : businesses.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-4 text-center text-sm text-gray-500">
                  No businesses found
                </td>
              </tr>
            ) : (
              businesses.map((business) => (
                <tr key={business.id}>
                  {/* ... existing columns ... */}
                  <td className="px-6 py-4 whitespace-nowrap">
                    <BusinessStatusBadge status={business.status} />
                    <div className="text-xs text-gray-500 mt-1">
                      Updated {new Date(business.status_updated_at).toLocaleDateString()}
                    </div>
                  </td>
                  {/* ... other columns ... */}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </>
  );
}