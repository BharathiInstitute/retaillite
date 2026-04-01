/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["**/src/__tests__/**/*.test.ts"],
  // Exclude emulator-dependent rules tests from default `npm test`
  // Run rules tests separately: npx jest --testPathPattern=rules
  testPathIgnorePatterns: ["/node_modules/", "rules[._]test\\.ts$"],
  moduleFileExtensions: ["ts", "js", "json"],
  transform: {
    "^.+\\.ts$": "ts-jest",
  },
  // Increase timeout for Firebase operations
  testTimeout: 10000,
};
