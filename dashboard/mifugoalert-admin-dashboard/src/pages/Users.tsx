import { useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { FiPhone, FiEdit2, FiTrash2, FiPlus } from "react-icons/fi";
import { useCollection } from "../hooks/useCollection";
import { addUser, updateUser, deleteUser, type NewUserInput } from "../lib/users";
import { toMillis } from "../lib/time";
import type { AppUser } from "../types";

type Role = "farmer" | "vet";
type Tab = "all" | Role;

interface FormState {
  role: Role;
  fullName: string;
  phone: string;
  area: string;
  email: string;
  isAvailable: boolean;
}

const EMPTY: FormState = { role: "farmer", fullName: "", phone: "", area: "", email: "", isAvailable: true };

const AVATAR_TINTS = ["#1B7A3D", "#B45309", "#1D4ED8", "#7C3AED", "#0E7490"];
function tintFor(name: string) {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = name.charCodeAt(i) + ((h << 5) - h);
  return AVATAR_TINTS[Math.abs(h) % AVATAR_TINTS.length];
}
function fmtDate(ts: unknown) {
  const ms = toMillis(ts as never);
  if (!ms) return "—";
  return new Date(ms).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
}

export default function Users() {
  const [params, setParams] = useSearchParams();
  const tabParam = params.get("role");
  const tab: Tab = tabParam === "vet" ? "vet" : tabParam === "farmer" ? "farmer" : "all";

  const users = useCollection<AppUser>("users");
  const [search, setSearch] = useState("");
  const [editing, setEditing] = useState<AppUser | null>(null);
  const [adding, setAdding] = useState(false);
  const [form, setForm] = useState<FormState>(EMPTY);
  const [busy, setBusy] = useState(false);

  const farmerCount = users.filter((u) => u.role === "farmer").length;
  const vetCount = users.filter((u) => u.role === "vet").length;

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return users
      .filter((u) => tab === "all" || u.role === tab)
      .filter((u) =>
        !q ||
        (u.fullName ?? "").toLowerCase().includes(q) ||
        (u.phone ?? "").toLowerCase().includes(q) ||
        (u.email ?? "").toLowerCase().includes(q) ||
        (u.area ?? "").toLowerCase().includes(q)
      )
      .sort((a, b) => (a.fullName ?? "").localeCompare(b.fullName ?? ""));
  }, [users, tab, search]);

  function setTab(next: Tab) {
    setParams(next === "all" ? {} : { role: next });
    setSearch("");
  }
  function openAdd() {
    setForm({ ...EMPTY, role: tab === "all" ? "farmer" : tab });
    setEditing(null);
    setAdding(true);
  }
  function openEdit(u: AppUser) {
    setForm({
      role: (u.role as Role) ?? "farmer",
      fullName: u.fullName ?? "",
      phone: u.phone ?? "",
      area: u.area ?? "",
      email: u.email ?? "",
      isAvailable: u.isAvailable ?? true,
    });
    setAdding(false);
    setEditing(u);
  }
  function closeModal() { setAdding(false); setEditing(null); }

  async function save() {
    setBusy(true);
    try {
      const role: Role = editing ? ((editing.role as Role) ?? "farmer") : form.role;
      const payload: NewUserInput = {
        role,
        fullName: form.fullName.trim(),
        phone: form.phone.trim(),
        area: form.area.trim(),
        email: form.email.trim(),
      };
      if (role === "vet") payload.isAvailable = form.isAvailable;
      if (editing) await updateUser(editing.id, payload);
      else await addUser(payload);
      closeModal();
    } finally {
      setBusy(false);
    }
  }

  async function toggleAvailable(u: AppUser) {
    await updateUser(u.id, { isAvailable: !(u.isAvailable ?? false) });
  }
  async function remove(u: AppUser) {
    if (window.confirm(`Delete ${u.fullName ?? "this user"}?`)) await deleteUser(u.id);
  }

  const addLabel = tab === "vet" ? "Add vet" : tab === "farmer" ? "Add farmer" : "Add user";
  const modalOpen = adding || editing !== null;
  const roleForFields: Role = adding ? form.role : ((editing?.role as Role) ?? "farmer");

  return (
    <>
      <div className="page-head">
        <div>
          <h2 className="page-title">User management</h2>
          <p className="page-sub">Farmers and veterinary professionals on the platform.</p>
        </div>
        <button className="btn-green icon-btn-lg" onClick={openAdd} title={addLabel}><FiPlus /></button>
      </div>

      <div className="seg">
        <button className={`seg-btn ${tab === "all" ? "active" : ""}`} onClick={() => setTab("all")}>All ({users.length})</button>
        <button className={`seg-btn ${tab === "farmer" ? "active" : ""}`} onClick={() => setTab("farmer")}>Farmers ({farmerCount})</button>
        <button className={`seg-btn ${tab === "vet" ? "active" : ""}`} onClick={() => setTab("vet")}>Vets ({vetCount})</button>
      </div>

      <input className="search" placeholder="Search by name, email, phone or area…"
             value={search} onChange={(e) => setSearch(e.target.value)} />

      <div className="table-wrap">
        <table className="user-table">
          <thead>
            <tr><th>User</th><th>Role</th><th>Region</th><th>Status</th><th>Joined</th><th></th></tr>
          </thead>
          <tbody>
            {filtered.length === 0 && <tr><td colSpan={6} className="empty">No users found.</td></tr>}
            {filtered.map((u) => {
              const isVet = u.role === "vet";
              return (
                <tr key={u.id}>
                  <td>
                    <div className="u-cell">
                      <span className="u-avatar" style={{ background: tintFor(u.fullName ?? "?") }}>
                        {(u.fullName ?? "?").slice(0, 1).toUpperCase()}
                      </span>
                      <div>
                        <div className="u-name">{u.fullName ?? "Unnamed"}</div>
                        <div className="u-sub">{u.email || u.phone || "—"}</div>
                      </div>
                    </div>
                  </td>
                  <td><span className="role-pill">{isVet ? "Vet" : "Farmer"}</span></td>
                  <td>{u.area ?? "—"}</td>
                  <td>
                    {isVet ? (
                      <button className={`pill ${u.isAvailable ? "pill-resolved" : "pill-pending"}`}
                              onClick={() => toggleAvailable(u)} title="Toggle availability">
                        {u.isAvailable ? "Available" : "Unavailable"}
                      </button>
                    ) : (
                      <span className="pill pill-resolved">Active</span>
                    )}
                  </td>
                  <td className="u-date">{fmtDate(u.createdAt)}</td>
                  <td>
                    <div className="row-actions">
                      <a className="btn-icon" href={`tel:${u.phone ?? ""}`} title="Call"><FiPhone /></a>
                      <button className="btn-icon" onClick={() => openEdit(u)} title="Edit"><FiEdit2 /></button>
                      <button className="btn-icon danger" onClick={() => remove(u)} title="Delete"><FiTrash2 /></button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {modalOpen && (
        <div className="modal-scrim" onClick={closeModal}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h3 className="modal-title">{editing ? "Edit" : "Add"} {roleForFields}</h3>
            {adding && (
              <>
                <label className="label">Role</label>
                <select className="field" value={form.role}
                        onChange={(e) => setForm({ ...form, role: e.target.value as Role })}>
                  <option value="farmer">Farmer</option>
                  <option value="vet">Vet</option>
                </select>
              </>
            )}
            <label className="label">Full name</label>
            <input className="field" value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} />
            <label className="label">Phone</label>
            <input className="field" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
            <label className="label">Area / Region</label>
            <input className="field" value={form.area} onChange={(e) => setForm({ ...form, area: e.target.value })} />
            <label className="label">Email</label>
            <input className="field" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
            {roleForFields === "vet" && (
              <label className="checkbox">
                <input type="checkbox" checked={form.isAvailable}
                       onChange={(e) => setForm({ ...form, isAvailable: e.target.checked })} />
                Available for consultations
              </label>
            )}
            <div className="modal-actions">
              <button className="btn-sm btn-ghost" onClick={closeModal} disabled={busy}>Cancel</button>
              <button className="btn-sm btn-green" onClick={save} disabled={busy || !form.fullName.trim()}>
                {busy ? "Saving…" : "Save"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}