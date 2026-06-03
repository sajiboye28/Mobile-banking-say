"use client";

import React, { createContext, useContext, useEffect, useState } from "react";

const PB_URL = process.env.NEXT_PUBLIC_POCKETBASE_URL || "http://127.0.0.1:8091";
const TOKEN_KEY = "pb_admin_token";
const RECORD_KEY = "pb_admin_record";

export interface AdminRecord {
  id: string;
  email: string;
  name?: string;
  [key: string]: unknown;
}

interface AuthContextType {
  user: AdminRecord | null;
  isAdmin: boolean;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  token: string | null;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  isAdmin: false,
  loading: true,
  login: async () => {},
  logout: async () => {},
  token: null,
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AdminRecord | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Restore session from localStorage on mount
  useEffect(() => {
    try {
      const storedToken = localStorage.getItem(TOKEN_KEY);
      const storedRecord = localStorage.getItem(RECORD_KEY);
      if (storedToken && storedRecord) {
        setToken(storedToken);
        setUser(JSON.parse(storedRecord) as AdminRecord);
      }
    } catch {
      // Ignore parse errors
    } finally {
      setLoading(false);
    }
  }, []);

  const login = async (email: string, password: string): Promise<void> => {
    const response = await fetch(
      `${PB_URL}/api/collections/_superusers/auth-with-password`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ identity: email, password }),
      }
    );

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(
        (errorData as { message?: string }).message ||
          "Invalid email or password."
      );
    }

    const data = (await response.json()) as { token: string; record: AdminRecord };

    if (!data.token || !data.record) {
      throw new Error("Unexpected response from authentication server.");
    }

    // Persist to localStorage
    localStorage.setItem(TOKEN_KEY, data.token);
    localStorage.setItem(RECORD_KEY, JSON.stringify(data.record));

    setToken(data.token);
    setUser(data.record);
  };

  const logout = async (): Promise<void> => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(RECORD_KEY);
    setToken(null);
    setUser(null);
  };

  const isAdmin = user !== null;

  return (
    <AuthContext.Provider value={{ user, isAdmin, loading, login, logout, token }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
