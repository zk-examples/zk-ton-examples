import type { Config } from 'jest';

const config: Config = {
    preset: 'ts-jest',
    globalSetup: './jest.setup.ts',
    cache: false, // disabled caching to prevent old Tact files from being used after a rebuild
    testEnvironment: '@ton/sandbox/jest-environment',
    testPathIgnorePatterns: ['/node_modules/', '/dist/', '<rootDir>/.cache/'],
    reporters: ['default', ['@ton/sandbox/jest-reporter', {}]],
    testTimeout: 30000,
    forceExit: true,
};

export default config;
