import type { InputHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        'h-11 w-full rounded-xl border border-[var(--border)] bg-[#0b1730]/80 px-3 text-sm text-[var(--foreground)] outline-none placeholder:text-[var(--muted)] focus:border-[#64e3be] focus:ring-2 focus:ring-[#64e3be]/25',
        className,
      )}
      {...props}
    />
  )
}
