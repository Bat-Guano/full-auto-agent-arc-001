import { useState, useEffect } from "react";
import "./App.css";

interface HealthStatus {
  status: string;
  detail?: string;
}

function App() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [healthError, setHealthError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/health")
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((data: HealthStatus) => setHealth(data))
      .catch((err: Error) => setHealthError(err.message));
  }, []);

  return (
    <div className="app">
      <header className="app-header">
        <h1>My App</h1>
        <p className="app-tagline">Application scaffold is running</p>
      </header>

      <main className="app-main">
        <section className="status-card">
          <h2>System Status</h2>
          <div className="status-indicator">
            {health ? (
              <span className="status-ok">
                API: {health.status}
              </span>
            ) : healthError ? (
              <span className="status-error">
                API unavailable ({healthError})
              </span>
            ) : (
              <span className="status-pending">Checking API health...</span>
            )}
          </div>
        </section>
      </main>

      <footer className="app-footer">
        <p>Vite + React + TypeScript &bull; FastAPI Backend</p>
      </footer>
    </div>
  );
}

export default App;
