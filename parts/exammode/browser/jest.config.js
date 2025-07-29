module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: [
    '**/?(*.)+(test).ts'
  ],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/main.ts', // Main is for configuration
    '!src/preload/**/*.ts', // Exclude preload files for now
    '!src/renderer/**/*.ts', // Exclude renderer files that require DOM
  ],
  moduleFileExtensions: ['ts', 'js', 'json'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  testTimeout: 10000,
  // Mock Electron modules
  moduleNameMapper: {
    '^electron$': '<rootDir>/tests/__mocks__/electron.ts',
  },
  restoreMocks: true,
};
