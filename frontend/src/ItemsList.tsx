import { useState, useEffect } from "react";

interface Item {
  id: number;
  name: string;
  done: boolean;
}

function ItemsList() {
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

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

  if (loading) return <p>Loading items...</p>;
  if (error) return <p role="alert">Error loading items: {error}</p>;

  return (
    <ul>
      {items.map((item) => (
        <li key={item.id} className={item.done ? "item-done" : "item-pending"}>
          {item.name}
        </li>
      ))}
    </ul>
  );
}

export default ItemsList;
