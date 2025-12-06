module.exports = {
	preset: "jest-expo",

	// use babel-jest for source files and dependencies that need transpilation
	transform: {
		"^.+\\.[tj]sx?$": "babel-jest",
	},

	// allow transforming expo and related packages (add outros pacotes se necessário)
	transformIgnorePatterns: [
		"node_modules/(?!(react-native|@react-native|expo|@expo|expo-modules-core|expo-status-bar|@unimodules|@react-navigation|@react-native-community)/)",
	],

	moduleFileExtensions: ["js", "jsx", "ts", "tsx", "json", "node"],

	// setup for testing-library/react-native
	setupFilesAfterEnv: ["<rootDir>/jest-setup.js"],

	// optionally increase timeout if some transforms take longer
	testTimeout: 10000,
};
