import React from "react";
import { render } from "@testing-library/react-native";
import App from "../App";

test("renders something from App", () => {
	const { getByText } = render(<App />);
	// Ajuste o padrão abaixo caso o texto do template Expo seja diferente na sua versão
	expect(getByText(/Testando template Autenticação|Open up/)).toBeTruthy();
});
