// Import all hero images
import equipmentImg from './equipment-rental.avif';
import vehicleImg from './vehicle-rental.avif';
import eventImg from './event-rental.jpg';
import recreationalImg from './recreational-rental.avif';

// Export hero slides configuration
export const HERO_SLIDES = [
  {
    image: equipmentImg,
    title: 'Equipment'
  },
  {
    image: vehicleImg,
    title: 'Vehicle'
  },
  {
    image: eventImg,
    title: 'Event'
  },
  {
    image: recreationalImg,
    title: 'Recreational'
  }
] as const;