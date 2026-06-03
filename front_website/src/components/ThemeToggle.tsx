import { useTheme } from '../context/ThemeContext'

export default function ThemeToggle() {
  const { theme, toggle } = useTheme()
  const isLight = theme === 'theme-light'

  return (
    <div className="switch-box">
      <label className="switch" aria-label="Toggle dark/light mode">
        <input
          type="checkbox"
          checked={isLight}
          onChange={toggle}
          id="slider"
        />
        <span className="slider round" />
      </label>
    </div>
  )
}
