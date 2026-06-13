import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import App from "./App";

describe("App", () => {
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
});
