import crypto from 'node:crypto';

const KEY_LENGTH = 64;
const SCRYPT_N = 16384;
const SCRYPT_R = 8;
const SCRYPT_P = 1;

function scryptAsync(password: string, salt: string, keyLength: number): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    crypto.scrypt(password, salt, keyLength, { N: SCRYPT_N, r: SCRYPT_R, p: SCRYPT_P }, (err, derivedKey) => {
      if (err) {
        reject(err);
        return;
      }
      resolve(derivedKey as Buffer);
    });
  });
}

export async function hashPassword(plain: string): Promise<string> {
  const salt = crypto.randomBytes(16).toString('base64url');
  const hashBuffer = await scryptAsync(plain, salt, KEY_LENGTH);
  return `scrypt$${SCRYPT_N}$${SCRYPT_R}$${SCRYPT_P}$${salt}$${hashBuffer.toString('base64url')}`;
}

export async function verifyPassword(plain: string, hashed: string): Promise<boolean> {
  const parts = hashed.split('$');
  if (parts.length !== 6 || parts[0] !== 'scrypt') {
    return false;
  }

  const [, n, r, p, salt, digest] = parts;
  const parsedN = Number(n);
  const parsedR = Number(r);
  const parsedP = Number(p);
  if (!Number.isInteger(parsedN) || !Number.isInteger(parsedR) || !Number.isInteger(parsedP)) {
    return false;
  }

  const derived = await new Promise<Buffer>((resolve, reject) => {
    crypto.scrypt(plain, salt, KEY_LENGTH, { N: parsedN, r: parsedR, p: parsedP }, (err, key) => {
      if (err) {
        reject(err);
        return;
      }
      resolve(key as Buffer);
    });
  });

  const expected = Buffer.from(digest, 'base64url');
  if (expected.length !== derived.length) {
    return false;
  }

  return crypto.timingSafeEqual(derived, expected);
}
