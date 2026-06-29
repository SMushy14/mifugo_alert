import { useState, type FormEvent } from "react";
import { Navigate } from "react-router-dom";
import { signInWithEmailAndPassword } from "firebase/auth";
import { FirebaseError } from "firebase/app";
import { auth } from "../lib/firebase";
import { useAuth } from "../auth/authContext";
import logo from "../assets/logo.png";

function authError(err: unknown): string {
  if (err instanceof FirebaseError) {
    switch (err.code) {
      case "auth/invalid-credential":
      case "auth/wrong-password":
      case "auth/user-not-found":
        return "Incorrect email or password.";
      case "auth/invalid-email":
        return "Enter a valid email address.";
      case "auth/too-many-requests":
        return "Too many attempts. Please try again later.";
      default:
        return "Sign in failed. Please try again.";
    }
  }
  return "Sign in failed. Please try again.";
}

export default function LoginPage() {
  const { user, loading: authLoading } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  async function signIn(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError("");
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
    } catch (err: unknown) {
      setError(authError(err));
      setSubmitting(false);
    }
  }

  if (authLoading) return <div className="loading-screen">Loading…</div>;
  if (user) return <Navigate to="/dashboard" replace />;

  return (
    <div className="login-page">
      <div className="login-inner">
        <div className="login-logo">
          <img src={logo} alt="MifugoAlert logo" />
        </div>
        <h1 className="login-title">MifugoAlert Admin</h1>
        <p className="login-sub">Restricted administration console</p>

        <form className="login-card" onSubmit={signIn}>
          <label className="label">Email</label>
          <input className="field" type="email" value={email}
                 onChange={(e) => setEmail(e.target.value)} placeholder="Email" />

          <label className="label">Password</label>
          <input className="field" type="password" value={password}
                 onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" />

          {error && <div className="error">{error}</div>}

          <button className="btn btn-primary" type="submit" disabled={submitting}>
            {submitting ? "Signing in…" : "Sign in"}
          </button>
        </form>
      </div>
    </div>
  );
}