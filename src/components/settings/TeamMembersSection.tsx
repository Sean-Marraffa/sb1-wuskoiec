import React from 'react';
import { TeamMembersList } from './TeamMembersList';
import { TeamInvites } from './TeamInvites';

export function TeamMembersSection() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <TeamMembersList />
      <TeamInvites />
    </div>
  );
}