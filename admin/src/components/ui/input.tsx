import type { InputHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        'h-11 w-full rounded-xl border border-[var(--border)] bg-white px-3 text-sm text-[var(--foreground)] outline-none placeholder:text-[var(--muted)] focus:border-[#14b8a6] focus:ring-2 focus:ring-[#14b8a6]/20',
        className,
      )}
      {...props}
    />
  )
}
