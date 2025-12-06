import React from "react";
import { render, screen } from "@testing-library/react";
import "@testing-library/jest-dom";
import App from "./App.jsx";

test("renders heading", () => {
	render(<App />);
	expect(screen.getByText(/Hello React Assignment|Hello React/i)).toBeInTheDocument();
});
