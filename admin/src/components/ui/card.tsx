import type { HTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        'rounded-2xl border border-[var(--border)] bg-[var(--card)]/90 backdrop-blur-xl shadow-[0_20px_60px_-30px_rgba(12,20,38,0.85)]',
        className,
      )}
      {...props}
    />
  )
}
