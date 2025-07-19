import { useState, useEffect } from 'react';

export function useLocalAuth() {
  const [role, setRole] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const storedRole = typeof window !== 'undefined' ? localStorage.getItem('userRole') : null;
    setRole(storedRole);
    setLoading(false);
  }, []);

  const logout = () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('userRole');
      setRole(null);
    }
  };

  return { role, loading, logout };
}

export function useIsMobile() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth <= 768);
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  return isMobile;
}