import { useState } from "react";
import { Link } from "react-router-dom";
import { FiUsers, FiUserCheck, FiFileText, FiAlertTriangle } from "react-icons/fi";
import { useCollection } from "../hooks/useCollection";
import { toMillis, timeAgo, isThisMonth, lastSevenMonths } from "../lib/time";
import StatCard from "../components/StatCard";
import ReportPill from "../components/ReportPill";
import DiseaseChart from "../components/DiseaseChart";
import type { AppUser, Case, ChartPoint } from "../types";

function lastNWeeks(n: number) {
  const weeks: { start: number; end: number; label: string }[] = [];
  const now = new Date();
  const day = (now.getDay() + 6) % 7;
  const monday = new Date(now);
  monday.setHours(0, 0, 0, 0);
  monday.setDate(now.getDate() - day);

  for (let i = n - 1; i >= 0; i--) {
    const start = new Date(monday);
    start.setDate(monday.getDate() - i * 7);
    const end = new Date(start);
    end.setDate(start.getDate() + 7);
    const label = `${start.getDate()}/${start.getMonth() + 1}`;
    weeks.push({ start: start.getTime(), end: end.getTime(), label });
  }
  return weeks;
}

export default function Overview() {
  const users = useCollection<AppUser>("users");
  const cases = useCollection<Case>("cases");

  const [range, setRange] = useState<"weekly" | "monthly">("monthly");

  const farmers = users.filter((u) => u.role === "farmer");
  const vets = users.filter((u) => u.role === "vet");
  const availableVets = vets.filter((v) => v.isAvailable === true).length;
  const openReports = cases.filter((c) => c.status !== "resolved").length;
  const alerts = cases.filter(
    (c) => (c.priority === "emergency" || c.isEmergency === true) && c.status !== "resolved"
  ).length;
  const newFarmers = farmers.filter((f) => isThisMonth(f.createdAt)).length;
  const newCases = cases.filter((c) => isThisMonth(c.createdAt)).length;

  const recent = [...cases]
    .sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt))
    .slice(0, 6);

  const monthlyData: ChartPoint[] = lastSevenMonths().map((slot) => {
    const inMonth = cases.filter((c) => {
      const ms = toMillis(c.createdAt);
      if (!ms) return false;
      const d = new Date(ms);
      return d.getFullYear() === slot.year && d.getMonth() === slot.month;
    });
    return {
      month: slot.label,
      reports: inMonth.length,
      resolved: inMonth.filter((c) => c.status === "resolved").length,
    };
  });

  const weeklyData: ChartPoint[] = lastNWeeks(8).map((wk) => {
    const inWeek = cases.filter((c) => {
      const ms = toMillis(c.createdAt);
      return ms && ms >= wk.start && ms < wk.end;
    });
    return {
      month: wk.label,
      reports: inWeek.length,
      resolved: inWeek.filter((c) => c.status === "resolved").length,
    };
  });

  const chartData = range === "weekly" ? weeklyData : monthlyData;

  return (
    <>
      <div className="stat-grid">
        <Link className="card-link" to="/dashboard/users?role=farmer">
          <StatCard
            label="Registered Farmers"
            value={farmers.length}
            caption={`${newFarmers} new this month`}
            icon={<FiUsers />}
            tint="green"
          />
        </Link>
        <Link className="card-link" to="/dashboard/users?role=vet">
          <StatCard
            label="Active Vets"
            value={vets.length}
            caption={`${availableVets} available now`}
            icon={<FiUserCheck />}
            tint="green"
          />
        </Link>
        <Link className="card-link" to="/dashboard/reports">
          <StatCard
            label="Open Disease Reports"
            value={openReports}
            caption={`${newCases} new this month`}
            icon={<FiFileText />}
            tint="amber"
          />
        </Link>
        <Link className="card-link" to="/dashboard/alerts">
          <StatCard
            label="Active Alerts"
            value={alerts}
            caption="emergency cases"
            icon={<FiAlertTriangle />}
            tint="red"
          />
        </Link>
      </div>

      <div className="card">
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            flexWrap: "wrap",
            gap: 12,
          }}
        >
          <div>
            <h2 className="card-title">Disease activity</h2>
            <p className="card-sub">
              {range === "weekly"
                ? "Reports vs resolved cases over the last 8 weeks."
                : "Reports vs resolved cases over the last 7 months."}
            </p>
          </div>
          <div className="seg">
            <button
              className={`seg-btn ${range === "weekly" ? "active" : ""}`}
              onClick={() => setRange("weekly")}
            >
              Weekly
            </button>
            <button
              className={`seg-btn ${range === "monthly" ? "active" : ""}`}
              onClick={() => setRange("monthly")}
            >
              Monthly
            </button>
          </div>
        </div>

        <DiseaseChart data={chartData} />
        <div className="legend">
          <span><i style={{ background: "#1B7A3D" }} /> Reports</span>
          <span><i style={{ background: "#D49F12" }} /> Resolved</span>
        </div>
      </div>

      <div className="card">
        <h2 className="card-title">Recent reports</h2>
        <p className="card-sub">Latest activity across regions.</p>
        {recent.length === 0 && <p className="empty">No reports yet.</p>}
        {recent.map((c) => (
          <div className="report-row" key={c.id}>
            <div>
              <div className="report-name">{c.farmerName ?? "Unknown"}</div>
              <div className="report-meta">
                {c.symptom ?? ""} · {c.area ?? ""}
              </div>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <span className="report-time">{timeAgo(c.createdAt)}</span>
              <ReportPill status={c.status} priority={c.priority} />
            </div>
          </div>
        ))}
      </div>
    </>
  );
}