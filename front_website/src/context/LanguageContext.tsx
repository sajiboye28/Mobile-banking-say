import { createContext, useContext, useEffect, useState } from 'react'
import { LangCode, Translations, translations } from '../i18n/translations'

interface LanguageContextValue {
  lang: LangCode
  t: Translations
  setLang: (code: LangCode) => void
}

const LanguageContext = createContext<LanguageContextValue>({
  lang: 'en',
  t: translations.en,
  setLang: () => {},
})

const RTL_LANGS: LangCode[] = ['ar']

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLangState] = useState<LangCode>(() => {
    const saved = localStorage.getItem('stcu_lang')
    return (saved && saved in translations) ? (saved as LangCode) : 'en'
  })

  const setLang = (code: LangCode) => {
    setLangState(code)
    localStorage.setItem('stcu_lang', code)
  }

  // Apply RTL direction
  useEffect(() => {
    const isRtl = RTL_LANGS.includes(lang)
    document.documentElement.setAttribute('dir', isRtl ? 'rtl' : 'ltr')
    document.documentElement.setAttribute('lang', lang)
  }, [lang])

  return (
    <LanguageContext.Provider value={{ lang, t: translations[lang], setLang }}>
      {children}
    </LanguageContext.Provider>
  )
}

export const useLanguage = () => useContext(LanguageContext)
