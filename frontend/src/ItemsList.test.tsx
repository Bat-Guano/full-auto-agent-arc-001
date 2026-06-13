import { describe, it, expect, beforeEach, vi } from "vitest";
import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import ItemsList from "./ItemsList";

const mockItems = {
  items: [
    { id: 1, name: "Define project scope", done: true },
    { id: 2, name: "Scaffold application", done: true },
    { id: 3, name: "Add domain feature", done: false },
  ],
};

const newItem = { id: 4, name: "New test item", done: false };

function mockFetchOnly(data: unknown, ok = true, status = 200) {
  globalThis.fetch = vi.fn().mockResolvedValue({
    ok,
    status,
    json: () => Promise.resolve(data),
  });
}

function mockFetchForGetAndPost(
  getData: unknown,
  postData: unknown = newItem,
) {
  globalThis.fetch = vi.fn().mockImplementation(
    (_url: RequestInfo | URL, init?: RequestInit) => {
      if (init?.method === "POST") {
        return Promise.resolve({
          ok: true,
          status: 201,
          json: () => Promise.resolve(postData),
        });
      }
      return Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve(getData),
      });
    },
  );
}

describe("ItemsList", () => {
  beforeEach(() => {
    mockFetchOnly(mockItems);
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

  describe("create item form", () => {
    beforeEach(() => {
      mockFetchForGetAndPost(mockItems);
    });

    it("renders the form with input and add button", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(screen.getByPlaceholderText(/New item name/i)).toBeInTheDocument();
      });

      expect(
        screen.getByRole("button", { name: /Add/i }),
      ).toBeInTheDocument();
    });

    it("creates a new item on form submit", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Define project scope/i),
        ).toBeInTheDocument();
      });

      const input = screen.getByPlaceholderText(
        /New item name/i,
      ) as HTMLInputElement;
      const button = screen.getByRole("button", { name: /Add/i });

      fireEvent.change(input, { target: { value: "New test item" } });
      fireEvent.click(button);

      await waitFor(() => {
        expect(
          screen.getByText(/New test item/i),
        ).toBeInTheDocument();
      });

      // Should have 4 list items now (3 original + 1 new)
      const items = screen.getAllByRole("listitem");
      expect(items).toHaveLength(4);

      // Input should be cleared
      expect(input.value).toBe("");
    });

    it("shows error when POST fails", async () => {
      // Override to fail the POST but let GET succeed
      globalThis.fetch = vi.fn().mockImplementation(
        (_url: RequestInfo | URL, init?: RequestInit) => {
          if (init?.method === "POST") {
            return Promise.reject(new Error("Server error"));
          }
          return Promise.resolve({
            ok: true,
            status: 200,
            json: () => Promise.resolve(mockItems),
          });
        },
      );

      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Define project scope/i),
        ).toBeInTheDocument();
      });

      const input = screen.getByPlaceholderText(
        /New item name/i,
      ) as HTMLInputElement;
      const button = screen.getByRole("button", { name: /Add/i });

      fireEvent.change(input, { target: { value: "Will fail" } });
      fireEvent.click(button);

      await waitFor(() => {
        expect(
          screen.getByText(/Error adding item: Server error/i),
        ).toBeInTheDocument();
      });
    });

    it("disables add button when input is empty", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(screen.getByPlaceholderText(/New item name/i)).toBeInTheDocument();
      });

      const button = screen.getByRole("button", { name: /Add/i });
      expect(button).toBeDisabled();
    });
  });
});
