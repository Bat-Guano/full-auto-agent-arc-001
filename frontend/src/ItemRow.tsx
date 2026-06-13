import { useState } from "react";

interface Item {
  id: number;
  name: string;
  done: boolean;
}

interface ItemRowProps {
  item: Item;
  onToggle: (item: Item) => void;
  onDelete: (item: Item) => void;
  onUpdate: (item: Item, name: string) => Promise<boolean>;
}

function ItemRow({ item, onToggle, onDelete, onUpdate }: ItemRowProps) {
  const [editing, setEditing] = useState(false);
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [editName, setEditName] = useState(item.name);
  const [saving, setSaving] = useState(false);

  const enterEdit = () => {
    setEditName(item.name);
    setEditing(true);
  };

  const handleSave = () => {
    const trimmed = editName.trim();
    if (!trimmed) return;
    setSaving(true);
    onUpdate(item, trimmed).then((success) => {
      if (success) {
        setEditing(false);
      }
      setSaving(false);
    });
  };

  const handleCancel = () => {
    setEditing(false);
  };

  if (confirmingDelete) {
    return (
      <li className={item.done ? "item-done" : "item-pending"}>
        <span className="confirm-text">Delete &ldquo;{item.name}&rdquo;?</span>
        <button
          onClick={() => {
            setConfirmingDelete(false);
            onDelete(item);
          }}
          className="btn-confirm-delete"
          aria-label={`Confirm delete ${item.name}`}
        >
          Delete
        </button>
        <button
          onClick={() => setConfirmingDelete(false)}
          className="btn-cancel-delete"
          aria-label={`Cancel delete ${item.name}`}
        >
          Cancel
        </button>
      </li>
    );
  }

  if (editing) {
    return (
      <li className={item.done ? "item-done" : "item-pending"}>
        <input
          type="checkbox"
          checked={item.done}
          disabled
          aria-label={`Toggle ${item.name}`}
        />
        <input
          type="text"
          className="edit-input"
          value={editName}
          onChange={(e) => setEditName(e.target.value)}
          aria-label={`Edit name for ${item.name}`}
        />
        <button
          onClick={handleSave}
          disabled={saving || !editName.trim()}
          className="btn-save"
          aria-label={`Save ${item.name}`}
        >
          {saving ? "Saving..." : "Save"}
        </button>
        <button
          onClick={handleCancel}
          disabled={saving}
          className="btn-cancel"
          aria-label={`Cancel editing ${item.name}`}
        >
          Cancel
        </button>
      </li>
    );
  }

  return (
    <li className={item.done ? "item-done" : "item-pending"}>
      <input
        type="checkbox"
        checked={item.done}
        onChange={() => onToggle(item)}
        aria-label={`Toggle ${item.name}`}
      />
      <span className="item-name">{item.name}</span>
      <button
        onClick={enterEdit}
        className="btn-edit"
        aria-label={`Edit ${item.name}`}
      >
        Edit
      </button>
      <button
        onClick={() => setConfirmingDelete(true)}
        className="btn-delete"
        aria-label={`Delete ${item.name}`}
      >
        Delete
      </button>
    </li>
  );
}

export default ItemRow;
