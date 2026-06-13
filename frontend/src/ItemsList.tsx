import { useState, useEffect, type FormEvent } from "react";

interface Item {
  id: number;
  name: string;
  done: boolean;
}

function ItemsList() {
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [newName, setNewName] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/items")
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((data: { items: Item[] }) => {
        setItems(data.items);
        setLoading(false);
      })
      .catch((err: Error) => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    const trimmed = newName.trim();
    if (!trimmed) return;

    setSubmitting(true);
    setSubmitError(null);

    fetch("/api/items", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: trimmed }),
    })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((newItem: Item) => {
        setItems((prev) => [...prev, newItem]);
        setNewName("");
        setSubmitting(false);
      })
      .catch((err: Error) => {
        setSubmitError(err.message);
        setSubmitting(false);
      });
  };

  const handleToggle = (item: Item) => {
    setActionError(null);
    const newDone = !item.done;

    fetch(`/api/items/${item.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ done: newDone }),
    })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((updated: Item) => {
        setItems((prev) =>
          prev.map((i) => (i.id === updated.id ? updated : i)),
        );
      })
      .catch((err: Error) => {
        setActionError(`Failed to toggle item: ${err.message}`);
      });
  };

  const handleDelete = (item: Item) => {
    setActionError(null);

    fetch(`/api/items/${item.id}`, { method: "DELETE" })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        setItems((prev) => prev.filter((i) => i.id !== item.id));
      })
      .catch((err: Error) => {
        setActionError(`Failed to delete item: ${err.message}`);
      });
  };

  if (loading) return <p>Loading items...</p>;
  if (error) return <p role="alert">Error loading items: {error}</p>;

  return (
    <div>
      <ul>
        {items.map((item) => (
          <li key={item.id} className={item.done ? "item-done" : "item-pending"}>
            <input
              type="checkbox"
              checked={item.done}
              onChange={() => handleToggle(item)}
              aria-label={`Toggle ${item.name}`}
            />
            {item.name}
            <button
              onClick={() => handleDelete(item)}
              aria-label={`Delete ${item.name}`}
            >
              Delete
            </button>
          </li>
        ))}
      </ul>

      {actionError && <p role="alert">{actionError}</p>}

      <form onSubmit={handleSubmit} className="add-item-form">
        <input
          type="text"
          placeholder="New item name"
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          disabled={submitting}
        />
        <button type="submit" disabled={submitting || !newName.trim()}>
          {submitting ? "Adding..." : "Add"}
        </button>
        {submitError && <p role="alert">Error adding item: {submitError}</p>}
      </form>
    </div>
  );
}

export default ItemsList;
