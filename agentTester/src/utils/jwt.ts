function base64Url(input: string): string {
  return Buffer.from(input).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

export function buildDevJwtToken(userId: string): string {
  const header = base64Url(JSON.stringify({ alg: 'none', typ: 'JWT' }));
  const payload = base64Url(JSON.stringify({ sub: userId, iat: Math.floor(Date.now() / 1000) }));
  return `tk-${header}.${payload}.sig`;
}
