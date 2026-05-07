module.exports = {
  apps: [
    {
      name: 'rest',
      cwd: './backend',
      script: '/Users/xsl/.bun/bin/bun',
      args: '--watch rest.ts',
      interpreter: 'none',
      autorestart: true,
      env: {
        NODE_ENV: 'development'
      }
    },
    {
      name: 'cron',
      cwd: './backend',
      script: '/Users/xsl/.bun/bin/bun',
      args: 'cron.ts',
      interpreter: 'none',
      autorestart: true,
      env: {
        NODE_ENV: 'development'
      }
    },
    {
      name: 'socket',
      cwd: './backend',
      script: '/Users/xsl/.bun/bin/bun',
      args: 'socket.ts',
      interpreter: 'none',
      autorestart: true,
      env: {
        NODE_ENV: 'development'
      }
    },
    {
      name: 'admin',
      cwd: './admin',
      script: '/opt/homebrew/bin/corepack',
      args: 'pnpm dev --host=0.0.0.0 --port=8300',
      interpreter: 'none',
      autorestart: true,
      env: {
        NODE_ENV: 'development'
      }
    },
    {
      name: 'h5',
      cwd: './h5',
      script: '/opt/homebrew/bin/corepack',
      args: 'pnpm dev',
      interpreter: 'none',
      autorestart: true,
      env: {
        NODE_ENV: 'development'
      }
    },
    {
      name: 'frpc',
      cwd: './ops/frp',
      script: './bin/darwin_arm64/frpc',
      args: '-c ./conf/frpc.toml',
      interpreter: 'none',
      autorestart: true
    }
  ]
};
