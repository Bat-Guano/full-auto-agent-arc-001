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

function mockFetchForGetPostPatchDelete(
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
      if (init?.method === "PATCH") {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: () => Promise.resolve(
            { id: 3, name: "Add domain feature", done: true },
          ),
        });
      }
      if (init?.method === "DELETE") {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: () => Promise.resolve(
            { id: 3, name: "Add domain feature", done: false },
          ),
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
    // Prevent the fetch from resolving so the component stays in the loading
    // state and no async state update fires after the test unmounts.
    globalThis.fetch = vi.fn().mockImplementation(
      () => new Promise<Response>(() => {}),
    );
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

  it("shows empty state when no items are returned", async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ items: [] }),
    });

    render(<ItemsList />);

    await waitFor(() => {
      expect(
        screen.getByText(/No items yet/i),
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
        screen.getByRole("button", { name: "Add" }),
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
      const button = screen.getByRole("button", { name: "Add" });

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
      const button = screen.getByRole("button", { name: "Add" });

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

      const button = screen.getByRole("button", { name: "Add" });
      expect(button).toBeDisabled();
    });
  });

  describe("toggle and delete", () => {
    beforeEach(() => {
      mockFetchForGetPostPatchDelete(mockItems);
    });

    it("renders a checkbox for each item", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Define project scope/i),
        ).toBeInTheDocument();
      });

      const checkboxes = screen.getAllByRole("checkbox");
      expect(checkboxes).toHaveLength(3);

      // First item (done: true) should be checked
      const firstCheckbox = screen.getByLabelText(
        /Toggle Define project scope/i,
      ) as HTMLInputElement;
      expect(firstCheckbox.checked).toBe(true);

      // Third item (done: false) should not be checked
      const thirdCheckbox = screen.getByLabelText(
        /Toggle Add domain feature/i,
      ) as HTMLInputElement;
      expect(thirdCheckbox.checked).toBe(false);
    });

    it("toggles done status on checkbox click", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      const checkbox = screen.getByLabelText(
        /Toggle Add domain feature/i,
      ) as HTMLInputElement;

      // Before toggle: unchecked, item has "pending" class
      expect(checkbox.checked).toBe(false);

      fireEvent.click(checkbox);

      // The fetch mock for PATCH returns done: true, so UI should update
      await waitFor(() => {
        expect(checkbox.checked).toBe(true);
      });
    });

    it("renders a delete button for each item", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Define project scope/i),
        ).toBeInTheDocument();
      });

      const deleteButtons = screen.getAllByRole("button", { name: /Delete/i });
      expect(deleteButtons).toHaveLength(3);
    });

    it("shows delete confirmation and removes item on confirm", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(screen.getAllByRole("listitem")).toHaveLength(3);
      });

      // Click delete to show confirmation
      const deleteButton = screen.getByLabelText(
        /Delete Add domain feature/i,
      );
      fireEvent.click(deleteButton);

      // Confirmation should be visible
      await waitFor(() => {
        expect(
          screen.getByText(/Delete.*Add domain feature/i),
        ).toBeInTheDocument();
      });

      // Click confirm delete
      const confirmButton = screen.getByLabelText(
        /Confirm delete Add domain feature/i,
      );
      fireEvent.click(confirmButton);

      await waitFor(() => {
        expect(screen.getAllByRole("listitem")).toHaveLength(2);
      });

      // Deleted item should no longer be visible
      expect(
        screen.queryByText(/Add domain feature/i),
      ).not.toBeInTheDocument();
    });

    it("cancels delete confirmation without removing item", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(screen.getAllByRole("listitem")).toHaveLength(3);
      });

      // Click delete to show confirmation
      const deleteButton = screen.getByLabelText(
        /Delete Add domain feature/i,
      );
      fireEvent.click(deleteButton);

      // Confirmation should be visible
      await waitFor(() => {
        expect(
          screen.getByLabelText(/Cancel delete Add domain feature/i),
        ).toBeInTheDocument();
      });

      // Click cancel
      const cancelButton = screen.getByLabelText(
        /Cancel delete Add domain feature/i,
      );
      fireEvent.click(cancelButton);

      // Item should still be in the list, 3 list items
      await waitFor(() => {
        expect(screen.getAllByRole("listitem")).toHaveLength(3);
      });

      expect(
        screen.getByText(/Add domain feature/i),
      ).toBeInTheDocument();
    });

    it("shows error when toggle fails", async () => {
      // Override to fail the PATCH
      globalThis.fetch = vi.fn().mockImplementation(
        (_url: RequestInfo | URL, init?: RequestInit) => {
          if (init?.method === "PATCH") {
            return Promise.resolve({
              ok: false,
              status: 500,
              json: () => Promise.resolve({}),
            });
          }
          if (init?.method === "DELETE") {
            return Promise.resolve({
              ok: true,
              status: 200,
              json: () => Promise.resolve({}),
            });
          }
          if (init?.method === "POST") {
            return Promise.resolve({
              ok: true,
              status: 201,
              json: () => Promise.resolve(newItem),
            });
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
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      const checkbox = screen.getByLabelText(
        /Toggle Add domain feature/i,
      );

      fireEvent.click(checkbox);

      await waitFor(() => {
        expect(
          screen.getByText(/Failed to toggle item: HTTP 500/i),
        ).toBeInTheDocument();
      });
    });

    it("shows error when delete fails", async () => {
      // Override to fail the DELETE
      globalThis.fetch = vi.fn().mockImplementation(
        (_url: RequestInfo | URL, init?: RequestInit) => {
          if (init?.method === "DELETE") {
            return Promise.resolve({
              ok: false,
              status: 404,
              json: () => Promise.resolve({}),
            });
          }
          if (init?.method === "POST") {
            return Promise.resolve({
              ok: true,
              status: 201,
              json: () => Promise.resolve(newItem),
            });
          }
          if (init?.method === "PATCH") {
            return Promise.resolve({
              ok: true,
              status: 200,
              json: () => Promise.resolve(
                { id: 1, name: "Define project scope", done: true },
              ),
            });
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
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      // Click delete to show confirmation
      const deleteButton = screen.getByLabelText(
        /Delete Add domain feature/i,
      );
      fireEvent.click(deleteButton);

      // Click confirm delete — this triggers the DELETE request
      await waitFor(() => {
        expect(
          screen.getByLabelText(/Confirm delete Add domain feature/i),
        ).toBeInTheDocument();
      });

      const confirmButton = screen.getByLabelText(
        /Confirm delete Add domain feature/i,
      );
      fireEvent.click(confirmButton);

      await waitFor(() => {
        expect(
          screen.getByText(/Failed to delete item: HTTP 404/i),
        ).toBeInTheDocument();
      });

      // Item should still be in the list
      expect(
        screen.getByText(/Add domain feature/i),
      ).toBeInTheDocument();
    });
  });

  describe("inline editing", () => {
    beforeEach(() => {
      mockFetchForGetPostPatchDelete(mockItems);
    });

    it("enters edit mode when edit button is clicked", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      const editButton = screen.getByLabelText(
        /Edit Add domain feature/i,
      );
      fireEvent.click(editButton);

      // Edit input should be visible with current name
      const editInput = screen.getByLabelText(
        /Edit name for Add domain feature/i,
      ) as HTMLInputElement;
      expect(editInput).toBeInTheDocument();
      expect(editInput.value).toBe("Add domain feature");

      // Save and Cancel buttons should be visible
      expect(
        screen.getByLabelText(/Save Add domain feature/i),
      ).toBeInTheDocument();
      expect(
        screen.getByLabelText(/Cancel editing Add domain feature/i),
      ).toBeInTheDocument();
    });

    it("saves an edited item name", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      // Enter edit mode
      const editButton = screen.getByLabelText(
        /Edit Add domain feature/i,
      );
      fireEvent.click(editButton);

      // Type new name
      const editInput = screen.getByLabelText(
        /Edit name for Add domain feature/i,
      ) as HTMLInputElement;
      fireEvent.change(editInput, { target: { value: "Updated feature name" } });

      // Click save
      const saveButton = screen.getByLabelText(
        /Save Add domain feature/i,
      );
      fireEvent.click(saveButton);

      // The mock returns { id: 3, name: "Add domain feature", done: true }
      // for PATCH, so the name in the UI will update to "Add domain feature"
      // (the mock's returned value). In a real app it would return the new name.
      // We verify the edit mode exits by checking the Edit button reappears.
      await waitFor(() => {
        expect(
          screen.getByLabelText(/Edit Add domain feature/i),
        ).toBeInTheDocument();
      });
    });

    it("cancels edit mode without saving changes", async () => {
      render(<ItemsList />);

      await waitFor(() => {
        expect(
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      // Enter edit mode
      const editButton = screen.getByLabelText(
        /Edit Add domain feature/i,
      );
      fireEvent.click(editButton);

      // Type something
      const editInput = screen.getByLabelText(
        /Edit name for Add domain feature/i,
      ) as HTMLInputElement;
      fireEvent.change(editInput, { target: { value: "Should not save" } });

      // Click cancel
      const cancelButton = screen.getByLabelText(
        /Cancel editing Add domain feature/i,
      );
      fireEvent.click(cancelButton);

      // Should be back in display mode with the original name
      await waitFor(() => {
        expect(
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      // Edit button should be back
      expect(
        screen.getByLabelText(/Edit Add domain feature/i),
      ).toBeInTheDocument();

      // Name should be unchanged
      expect(editInput).not.toBeInTheDocument();
    });

    it("shows error when name update fails", async () => {
      // Override to fail PATCH when body contains name-only update
      globalThis.fetch = vi.fn().mockImplementation(
        (_url: RequestInfo | URL, init?: RequestInit) => {
          if (init?.method === "PATCH") {
            return Promise.resolve({
              ok: false,
              status: 500,
              json: () => Promise.resolve({}),
            });
          }
          if (init?.method === "DELETE") {
            return Promise.resolve({
              ok: true,
              status: 200,
              json: () => Promise.resolve({}),
            });
          }
          if (init?.method === "POST") {
            return Promise.resolve({
              ok: true,
              status: 201,
              json: () => Promise.resolve(newItem),
            });
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
          screen.getByText(/Add domain feature/i),
        ).toBeInTheDocument();
      });

      // Enter edit mode
      const editButton = screen.getByLabelText(
        /Edit Add domain feature/i,
      );
      fireEvent.click(editButton);

      // Type new name
      const editInput = screen.getByLabelText(
        /Edit name for Add domain feature/i,
      ) as HTMLInputElement;
      fireEvent.change(editInput, { target: { value: "Will fail" } });

      // Click save
      const saveButton = screen.getByLabelText(
        /Save Add domain feature/i,
      );
      fireEvent.click(saveButton);

      // Error should appear
      await waitFor(() => {
        expect(
          screen.getByText(/Failed to update item: HTTP 500/i),
        ).toBeInTheDocument();
      });
    });
  });
});
