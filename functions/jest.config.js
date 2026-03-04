/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["**/src/__tests__/**/*.test.ts"],
  // Exclude emulator-dependent rules tests from default `npm test`
  // Run rules tests separately: npx jest src/__tests__/rules.test.ts
  testPathIgnorePatterns: ["/node_modules/", "rules\\.test\\.ts$"],
  moduleFileExtensions: ["ts", "js", "json"],
  transform: {
    "^.+\\.ts$": "ts-jest",
  },
  // Increase timeout for Firebase operations
  testTimeout: 10000,
};
