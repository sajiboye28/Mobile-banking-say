import { useScrollY } from '../hooks/useScrollY'

export default function GoTop() {
  const scrollY = useScrollY()
  const isActive = scrollY > 600

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <div
      className={`go-top${isActive ? ' active' : ''}`}
      onClick={scrollToTop}
      role="button"
      tabIndex={0}
      aria-label="Scroll to top"
      onKeyDown={e => e.key === 'Enter' && scrollToTop()}
    >
      <i className="bx bx-up-arrow-alt" />
    </div>
  )
}
