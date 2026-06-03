export interface UserModel {
  id: string;
  email: string;
  fullName: string;
  balance: number;
  accountNumber?: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  postalCode?: string;
  accountType: string; // savings | checking | premium | business | student | joint
  accountStatus: string; // active | pending | suspended | closed | frozen
  canTransact: boolean;
  tccCode?: string;
  kycStatus: string; // not_submitted | pending | approved | rejected | unverified
  avatar?: string;       // PocketBase file field — stores filename; build URL with PB_URL
  profilePicUrl?: string; // legacy text field (kept for back-compat)
  two_fa_enabled: boolean;
  login_alerts_enabled: boolean;
  created?: string;
}

export interface TransactionModel {
  id: string;
  userId: string;
  transactionId?: string;
  amount: number;
  type: 'Credit' | 'Debit' | string;
  status: 'Success' | 'Pending' | 'Failed' | string;
  description?: string;
  relatedUserId?: string;
  relatedUserName?: string;
  recipient?: unknown;
  source?: string;
  created: string;
}

export interface NotificationModel {
  id: string;
  userId: string;
  title: string;
  message: string;
  body?: string;
  type?: string;
  isRead: boolean;
  transactionId?: string;
  created: string;
}

// ── VirtualCard ──────────────────────────────────────────────────────────────
export interface VirtualCard {
  id: string;
  userId: string;
  cardNumber: string;
  cvv: string;
  expiryMonth: number;
  expiryYear: number;
  cardholderName: string;
  isFrozen: boolean;
  dailyLimit: number;
  monthlyLimit: number;
  created: string;
}

// ── SavingsGoal ──────────────────────────────────────────────────────────────
export interface SavingsGoal {
  id: string;
  userId: string;
  name: string;
  targetAmount: number;
  currentAmount: number;
  icon: string;
  color: string;
  deadline?: string;
  isCompleted: boolean;
  created: string;
}

// ── Loan ─────────────────────────────────────────────────────────────────────
export interface Loan {
  id: string;
  userId: string;
  amount: number;
  purpose: string;
  termMonths: number;
  interestRate: number;
  monthlyPayment: number;
  status: 'pending' | 'approved' | 'rejected' | 'active' | 'closed';
  rejectionReason?: string;
  created: string;
}

// ── BillPayment ──────────────────────────────────────────────────────────────
export interface BillPayment {
  id: string;
  userId: string;
  category: string;
  biller: string;
  accountNumber: string;
  amount: number;
  status: 'success' | 'pending' | 'failed';
  created: string;
}
