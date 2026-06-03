import { createContext, useContext, useEffect, useState } from 'react'

type Theme = 'theme-dark' | 'theme-light'

interface ThemeContextValue {
  theme: Theme
  toggle: () => void
}

const ThemeContext = createContext<ThemeContextValue>({
  theme: 'theme-dark',
  toggle: () => {},
})

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<Theme>(() => {
    const saved = localStorage.getItem('leve_theme')
    return (saved === 'theme-light' || saved === 'theme-dark') ? saved : 'theme-dark'
  })

  useEffect(() => {
    document.documentElement.className = theme
    localStorage.setItem('leve_theme', theme)
  }, [theme])

  const toggle = () =>
    setTheme(prev => (prev === 'theme-dark' ? 'theme-light' : 'theme-dark'))

  return (
    <ThemeContext.Provider value={{ theme, toggle }}>
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => useContext(ThemeContext)
