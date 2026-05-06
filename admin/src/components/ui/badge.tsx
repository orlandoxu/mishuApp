import type { HTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export function Badge({ className, ...props }: HTMLAttributes<HTMLSpanElement>) {
  return (
    <span
      className={cn('inline-flex items-center rounded-full bg-[#eef3ff] px-2.5 py-1 text-xs font-medium text-[#3f5273]', className)}
      {...props}
    />
  )
}
