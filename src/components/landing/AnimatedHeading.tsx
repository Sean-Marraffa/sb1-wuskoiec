import React, { useEffect, useState } from 'react';

interface AnimatedHeadingProps {
  businessType: string;
}

export function AnimatedHeading({ businessType }: AnimatedHeadingProps) {
  const [isAnimating, setIsAnimating] = useState(false);
  const [width, setWidth] = useState('0px');

  const getFontSize = () => {
    if (window.innerWidth < 640) return '2rem'; // text-4xl
    if (window.innerWidth < 768) return '3rem'; // text-5xl
    return '3.75rem'; // text-6xl
  };

  useEffect(() => {
    // Start animation
    setIsAnimating(true);
    
    // Measure the width needed for the new text
    const span = document.createElement('span');
    span.style.visibility = 'hidden';
    span.style.position = 'absolute';
    span.style.fontSize = getFontSize();
    span.style.fontWeight = '700'; // font-bold equivalent
    span.innerText = businessType;
    document.body.appendChild(span);
    const newWidth = `${span.offsetWidth}px`;
    document.body.removeChild(span);
    
    // Animate to new width
    setWidth(newWidth);

    // Reset animation after transition
    const timer = setTimeout(() => setIsAnimating(false), 500);
    return () => clearTimeout(timer);
  }, [businessType]);

  return (
    <h1 className="text-3xl sm:text-5xl md:text-6xl font-bold text-white mb-6 px-4 flex flex-col sm:flex-row items-center justify-center gap-1 sm:gap-3">
      <span className="whitespace-nowrap">Streamline your</span>
      <div className="flex items-center min-w-0 my-1 sm:my-0">
        <div 
          className="relative overflow-hidden transition-all duration-500 ease-in-out max-w-[200px] sm:max-w-none"
          style={{ width }}
        >
          <span
            className={`inline-block transition-all duration-500 ${
              isAnimating
                ? 'opacity-0 transform -translate-y-full'
                : 'opacity-100 transform translate-y-0'
            }`}
          >
            {businessType}
          </span>
        </div>
      </div>
      <span className="whitespace-nowrap">Rentals</span>
    </h1>
  );
}