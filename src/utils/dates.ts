// Format a date string to local date, handling timezone offset correctly
export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  
  // Get the timezone offset in minutes and convert to milliseconds
  const timezoneOffset = date.getTimezoneOffset() * 60000;
  
  // Add the offset to get the local date
  const localDate = new Date(date.getTime() + timezoneOffset);
  
  // Format the date
  return localDate.toLocaleDateString();
}