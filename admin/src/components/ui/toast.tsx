import { useEffect, useState } from 'react'

type ToastPayload = {
  id: number
  message: string
  tone: 'success' | 'error'
}

type ToastItem = ToastPayload & {
  leaving?: boolean
}

const TOAST_EVENT = 'admin-toast'

function emitToast(message: string, tone: ToastPayload['tone']) {
  const trimmed = message.trim()
  if (!trimmed) return
  window.dispatchEvent(
    new CustomEvent<ToastPayload>(TOAST_EVENT, {
      detail: { id: Date.now() + Math.floor(Math.random() * 1000), message: trimmed, tone },
    }),
  )
}

export const toast = {
  success(message: string) {
    emitToast(message, 'success')
  },
  error(message: string) {
    emitToast(message, 'error')
  },
}

export function ToastViewport() {
  const [items, setItems] = useState<ToastItem[]>([])

  useEffect(() => {
    const handler = (event: Event) => {
      const payload = (event as CustomEvent<ToastPayload>).detail
      setItems((prev) => [...prev, payload].slice(-3))
      window.setTimeout(() => {
        setItems((prev) => prev.map((item) => (item.id === payload.id ? { ...item, leaving: true } : item)))
      }, 1550)
      window.setTimeout(() => {
        setItems((prev) => prev.filter((item) => item.id !== payload.id))
      }, 1950)
    }

    window.addEventListener(TOAST_EVENT, handler)
    return () => window.removeEventListener(TOAST_EVENT, handler)
  }, [])

  if (items.length === 0) return null

  return (
    <div className="pointer-events-none fixed left-1/2 top-5 z-[1000] flex -translate-x-1/2 flex-col gap-2.5">
      {items.map((item) => (
        <div
          key={item.id}
          className={
            item.tone === 'success'
              ? `min-w-[140px] rounded-xl border border-[#bfe9d8] bg-[#e9faf3] px-5 py-2.5 text-center text-sm font-medium text-[#0f9f70] shadow-[0_12px_24px_-18px_rgba(15,159,112,0.5)] transition-all duration-300 ${item.leaving ? 'translate-y-[-8px] opacity-0' : 'translate-y-0 opacity-100'} animate-[toast-drop-in_300ms_cubic-bezier(0.22,1,0.36,1)]`
              : `min-w-[140px] rounded-xl border border-[#f5c2cc] bg-[#fff0f3] px-5 py-2.5 text-center text-sm font-medium text-[#cf2f52] shadow-[0_12px_24px_-18px_rgba(207,47,82,0.4)] transition-all duration-300 ${item.leaving ? 'translate-y-[-8px] opacity-0' : 'translate-y-0 opacity-100'} animate-[toast-drop-in_300ms_cubic-bezier(0.22,1,0.36,1)]`
          }
        >
          {item.message}
        </div>
      ))}
    </div>
  )
}
