import type { HTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        'rounded-2xl border border-[var(--border)] bg-[var(--card)] shadow-[0_18px_44px_-26px_rgba(30,42,62,0.28)]',
        className,
      )}
      {...props}
    />
  )
}
