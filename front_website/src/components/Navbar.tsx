import { useState, useEffect, useRef } from 'react'
import { useScrollY } from '../hooks/useScrollY'
import { WEB_APP_URL } from '../config'
import { useLanguage } from '../context/LanguageContext'

export default function Navbar() {
  const scrollY = useScrollY()
  const isSticky = scrollY > 120
  const [mobileOpen, setMobileOpen] = useState(false)
  const navRef = useRef<HTMLDivElement>(null)
  const { t } = useLanguage()

  // Close on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (navRef.current && !navRef.current.contains(e.target as Node)) {
        setMobileOpen(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const close = () => setMobileOpen(false)

  return (
    <div className={`navbar-area${isSticky ? ' is-sticky' : ''}`} ref={navRef}>

      {/* ── Desktop / tablet navbar ── */}
      <div className="main-navbar">
        <div className="container">
          <nav className="navbar navbar-expand-md navbar-light">

            {/* Logo */}
            <a className="navbar-brand" href="#home" onClick={close}>
              <img src="/logo.png"  width="150" className="black-logo" alt="STCU" />
              <img src="/logo1.png" width="150" className="white-logo" alt="STCU" />
            </a>

            {/* Hamburger for < md */}
            <button
              className="navbar-toggler"
              type="button"
              aria-label="Toggle navigation"
              aria-expanded={mobileOpen}
              onClick={() => setMobileOpen(v => !v)}
            >
              <span className="navbar-toggler-icon" />
            </button>

            {/* Collapsible content */}
            <div
              className={`collapse navbar-collapse mean-menu${mobileOpen ? ' show' : ''}`}
              id="navbarMain"
            >
              {/* Nav links — margin:auto centres them (from style.css) */}
              <ul className="navbar-nav">
                <li className="nav-item">
                  <a href="#home" className="nav-link active" onClick={close}>
                    {t.home} <i className="bx bx-chevron-down" />
                  </a>
                </li>
                <li className="nav-item">
                  <a href="#about" className="nav-link" onClick={close}>
                    {t.aboutUs}
                  </a>
                </li>
              </ul>

              {/* Open Account button — pushed to the right */}
              <div className="others-options d-flex align-items-center">
                <div className="option-item">
                  <a
                    href={`${WEB_APP_URL}/register`}
                    className="default-btn"
                    onClick={close}
                  >
                    {t.openAccount}
                  </a>
                </div>
              </div>
            </div>

          </nav>
        </div>
      </div>

    </div>
  )
}
