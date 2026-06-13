import { describe, it, expect, beforeEach, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import ItemsList from "./ItemsList";

const mockItems = {
  items: [
    { id: 1, name: "Define project scope", done: true },
    { id: 2, name: "Scaffold application", done: true },
    { id: 3, name: "Add domain feature", done: false },
  ],
};

function mockFetch(data: unknown, ok = true, status = 200) {
  globalThis.fetch = vi.fn().mockResolvedValue({
    ok,
    status,
    json: () => Promise.resolve(data),
  });
}

describe("ItemsList", () => {
  beforeEach(() => {
    mockFetch(mockItems);
  });

  it("shows loading message initially", () => {
    render(<ItemsList />);
    expect(screen.getByText(/Loading items/i)).toBeInTheDocument();
  });

  it("renders a list of items after fetch", async () => {
    render(<ItemsList />);

    await waitFor(() => {
      expect(
        screen.getByText(/Define project scope/i),
      ).toBeInTheDocument();
    });

    expect(screen.getByText(/Scaffold application/i)).toBeInTheDocument();
    expect(screen.getByText(/Add domain feature/i)).toBeInTheDocument();
  });

  it("renders each item as a list item", async () => {
    render(<ItemsList />);

    await waitFor(() => {
      const items = screen.getAllByRole("listitem");
      expect(items).toHaveLength(3);
    });
  });

  it("shows error state when fetch fails", async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new Error("Network error"));

    render(<ItemsList />);

    await waitFor(() => {
      expect(screen.getByRole("alert")).toBeInTheDocument();
      expect(
        screen.getByText(/Error loading items: Network error/i),
      ).toBeInTheDocument();
    });
  });
});
