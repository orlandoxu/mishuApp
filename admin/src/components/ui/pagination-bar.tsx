import { Button } from '@/components/ui/button'

type PaginationBarProps = {
  page: number
  total: number
  pageSize: number
  pageSizeOptions?: number[]
  onPageChange: (next: number) => void
  onPageSizeChange: (next: number) => void
}

function buildPageNumbers(page: number, totalPages: number): Array<number | '...'> {
  if (totalPages <= 7) return Array.from({ length: totalPages }, (_, i) => i + 1)
  if (page <= 4) return [1, 2, 3, 4, 5, '...', totalPages]
  if (page >= totalPages - 3) return [1, '...', totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages]
  return [1, '...', page - 1, page, page + 1, '...', totalPages]
}

export function PaginationBar({
  page,
  total,
  pageSize,
  pageSizeOptions = [10, 20, 50],
  onPageChange,
  onPageSizeChange,
}: PaginationBarProps) {
  const totalPages = Math.max(1, Math.ceil(total / pageSize))
  const pages = buildPageNumbers(page, totalPages)

  return (
    <div className="mt-3 flex shrink-0 items-center justify-between rounded-2xl border border-[#dbe4f2] bg-white px-4 py-3 shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)]">
      <div className="text-sm font-medium text-[#6f7f99]">第 {page} / {totalPages} 页，共 {total} 条</div>
      <div className="flex items-center gap-2">
        <select
          value={pageSize}
          onChange={(e) => onPageSizeChange(Number(e.target.value))}
          className="h-10 rounded-xl border border-[#ccd8ea] bg-white px-3 text-sm text-[#344864]"
        >
          {pageSizeOptions.map((item) => (
            <option value={item} key={item}>{item} / 页</option>
          ))}
        </select>

        <Button size="sm" variant="outline" disabled={page <= 1} onClick={() => onPageChange(Math.max(1, page - 1))}>上一页</Button>

        {pages.map((item, idx) => {
          if (item === '...') return <span key={`ellipsis-${idx}`} className="px-1 text-sm text-[#8ea0bc]">...</span>
          const active = item === page
          return (
            <button
              key={item}
              onClick={() => onPageChange(item)}
              className={active
                ? 'h-10 min-w-10 rounded-xl border border-[#8aa6d4] bg-[#e8f0ff] px-2 text-sm font-bold text-[#1f365b]'
                : 'h-10 min-w-10 rounded-xl border border-[#d8e0ee] bg-white px-2 text-sm text-[#465f82] hover:bg-[#f3f7ff]'}
            >
              {item}
            </button>
          )
        })}

        <Button size="sm" variant="outline" disabled={page >= totalPages} onClick={() => onPageChange(Math.min(totalPages, page + 1))}>下一页</Button>
      </div>
    </div>
  )
}
