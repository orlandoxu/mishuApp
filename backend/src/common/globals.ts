import { ok as okImpl } from './response';

const g = globalThis as typeof globalThis & {
  ok?: typeof okImpl;
};

if (!g.ok) {
  g.ok = okImpl;
}
