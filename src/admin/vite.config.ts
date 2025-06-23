// vite.config.ts - Fixed TypeScript version
import { mergeConfig, type UserConfig } from 'vite';

export default (config: UserConfig): UserConfig => {
  return mergeConfig(config, {
    resolve: {
      alias: {
        '@': '/src',
      },
    },
    server: {
      allowedHosts: 'all',
      host: '0.0.0.0',
      hmr: {
        port: 1337,
        clientPort: 1337,
      },
      // Additional server options for ALB
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,PUT,POST,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Content-Length, X-Requested-With',
      },
    },
    preview: {
      allowedHosts: 'all',
      host: '0.0.0.0',
      port: 1337,
    },
    build: {
      rollupOptions: {
        external: [],
      },
    },
    // Force disable host checking
    define: {
      'process.env.DANGEROUSLY_DISABLE_HOST_CHECK': '"true"',
    },
  });
};