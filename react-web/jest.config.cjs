module.exports = {
	testEnvironment: "jest-environment-jsdom",
	testEnvironmentOptions: { resources: "usable" },
	transform: {
		"^.+\\.[tj]sx?$": "babel-jest",
	},
	setupFilesAfterEnv: ["<rootDir>/src/setupTests.js"],
	transformIgnorePatterns: ["/node_modules/"],
	moduleFileExtensions: ["js", "jsx", "ts", "tsx", "json", "node"],
	moduleNameMapper: {
		"\\.(css|less|scss|sass)$": "<rootDir>/__mocks__/styleMock.js",
		"\\.(gif|ttf|eot|svg|png|jpg|jpeg)$": "<rootDir>/__mocks__/fileMock.js",
	},
};
