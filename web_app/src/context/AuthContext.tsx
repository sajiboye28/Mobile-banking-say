import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { pb, API_URL } from '../services/pb';
import type { UserModel } from '../models/types';

interface AuthContextValue {
  user: UserModel | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<UserModel | null>(null);
  const [loading, setLoading] = useState(true);

  const loadUser = useCallback(async (id: string): Promise<UserModel | null> => {
    try {
      const record = await pb.collection('users').getOne(id);
      return record as unknown as UserModel;
    } catch {
      return null;
    }
  }, []);

  const refreshUser = useCallback(async () => {
    const id = pb.authStore.record?.id;
    if (!id) return;
    const u = await loadUser(id);
    setUser(u);
  }, [loadUser]);

  // Initial auth check
  useEffect(() => {
    const init = async () => {
      if (pb.authStore.isValid && pb.authStore.record?.id) {
        const u = await loadUser(pb.authStore.record.id);
        setUser(u);
      }
      setLoading(false);
    };
    init();
  }, [loadUser]);

  // Listen for auth store changes (token expiry, etc.)
  useEffect(() => {
    const unsub = pb.authStore.onChange(async (_token, record) => {
      if (record?.id) {
        const u = await loadUser(record.id);
        setUser(u);
      } else {
        setUser(null);
      }
    });
    return () => {
      if (typeof unsub === 'function') unsub();
    };
  }, [loadUser]);

  // Realtime user record subscription
  useEffect(() => {
    if (!user?.id) return;

    let unsubscribe: (() => void) | null = null;

    pb.collection('users')
      .subscribe(user.id, (e) => {
        if (e.action === 'update') {
          setUser(e.record as unknown as UserModel);
        }
      })
      .then((fn) => {
        unsubscribe = fn;
      })
      .catch(() => {
        // Realtime not critical; ignore errors
      });

    return () => {
      if (unsubscribe) unsubscribe();
      else pb.collection('users').unsubscribe(user.id).catch(() => {});
    };
  }, [user?.id]);

  const signIn = async (email: string, password: string) => {
    // POST to our own Next.js server — credentials never go directly to PocketBase
    // from the browser. The server makes the PocketBase call internally.
    const res = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || 'Invalid email or password.');
    }

    const { token, record } = await res.json();

    // Re-hydrate the PocketBase SDK auth store with the server-issued token.
    // From here on all SDK calls (getOne, subscribe, etc.) carry this token
    // and go through the Vite proxy — same-origin, no CORS.
    pb.authStore.save(token, record);

    const u = await loadUser(record.id);
    if (!u) throw new Error('Could not load user record');
    setUser(u);
  };

  const signOut = () => {
    pb.authStore.clear();
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, signIn, signOut, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
