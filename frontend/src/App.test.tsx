import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import App from "./App";

describe("App", () => {
  beforeEach(() => {
    // Use a never-resolving promise so no async state update fires after
    // the test ends — prevents "not wrapped in act(...)" warnings.
    // Tests that check async behavior should override this mock.
    globalThis.fetch = vi.fn().mockImplementation(
      () => new Promise<Response>(() => {}),
    );
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("renders the landing page heading", () => {
    render(<App />);
    expect(
      screen.getByRole("heading", { name: /My App/i }),
    ).toBeInTheDocument();
  });

  it("renders the tagline", () => {
    render(<App />);
    expect(
      screen.getByText(/Application scaffold is running/i),
    ).toBeInTheDocument();
  });

  it("renders the footer", () => {
    render(<App />);
    expect(
      screen.getByText(/Vite \+ React \+ TypeScript/i),
    ).toBeInTheDocument();
  });

  it("renders the items section heading", () => {
    render(<App />);
    expect(
      screen.getByRole("heading", { name: /Items/i }),
    ).toBeInTheDocument();
  });
});
