import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import BottomNav from './components/BottomNav';

// Screens
import LoginScreen from './screens/LoginScreen';
import RegisterScreen from './screens/RegisterScreen';
import HomeScreen from './screens/HomeScreen';
import PendingScreen from './screens/PendingScreen';
import TransactionsScreen from './screens/TransactionsScreen';
import NotificationsScreen from './screens/NotificationsScreen';
import ProfileScreen from './screens/ProfileScreen';
import SettingsScreen from './screens/SettingsScreen';
import KycScreen from './screens/KycScreen';
import CardsScreen from './screens/CardsScreen';
import SavingsScreen from './screens/SavingsScreen';
import LoansScreen from './screens/LoansScreen';
import BillsScreen from './screens/BillsScreen';
import SendMoneyScreen from './screens/SendMoneyScreen';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-surface">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (user.accountStatus === 'pending') {
    return <Navigate to="/pending" replace />;
  }

  return <>{children}</>;
}

function AppShell() {
  const { user, loading } = useAuth();
  const location = useLocation();

  const publicRoutes = ['/login', '/register', '/pending'];
  const isPublic = publicRoutes.includes(location.pathname);
  const showNav = !loading && !!user && user.accountStatus === 'active' && !isPublic;

  return (
    <div className="min-h-screen bg-[#0a0a0a] flex items-start justify-center">
      {/* Phone-sized container */}
      <div className="relative w-full max-w-[430px] min-h-screen bg-surface phone-container overflow-hidden">
        <Routes>
          {/* Public routes */}
          <Route path="/login" element={<LoginScreen />} />
          <Route path="/register" element={<RegisterScreen />} />
          <Route path="/pending" element={<PendingScreen />} />

          {/* Protected routes */}
          <Route path="/" element={<ProtectedRoute><HomeScreen /></ProtectedRoute>} />
          <Route path="/send" element={<ProtectedRoute><SendMoneyScreen /></ProtectedRoute>} />
          <Route path="/transactions" element={<ProtectedRoute><TransactionsScreen /></ProtectedRoute>} />
          <Route path="/notifications" element={<ProtectedRoute><NotificationsScreen /></ProtectedRoute>} />
          <Route path="/profile" element={<ProtectedRoute><ProfileScreen /></ProtectedRoute>} />
          <Route path="/settings" element={<ProtectedRoute><SettingsScreen /></ProtectedRoute>} />
          <Route path="/kyc" element={<ProtectedRoute><KycScreen /></ProtectedRoute>} />
          <Route path="/cards" element={<ProtectedRoute><CardsScreen /></ProtectedRoute>} />
          <Route path="/savings" element={<ProtectedRoute><SavingsScreen /></ProtectedRoute>} />
          <Route path="/loans" element={<ProtectedRoute><LoansScreen /></ProtectedRoute>} />
          <Route path="/bills" element={<ProtectedRoute><BillsScreen /></ProtectedRoute>} />

          {/* Catch-all */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>

        {showNav && <BottomNav />}
      </div>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppShell />
      </AuthProvider>
    </BrowserRouter>
  );
}
