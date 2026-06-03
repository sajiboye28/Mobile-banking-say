import { WEB_APP_URL } from '../config'
import { useLanguage } from '../context/LanguageContext'
import { LangCode } from '../i18n/translations'

const LANGUAGES: { code: LangCode; label: string }[] = [
  { code: 'en', label: 'English' },
  { code: 'ar', label: 'العربيّة' },
  { code: 'de', label: 'Deutsch' },
  { code: 'pt', label: 'Português' },
  { code: 'zh', label: '简体中文' },
]

export default function TopHeader() {
  const { lang, setLang, t } = useLanguage()

  return (
    <div className="top-header-area">
      <div className="container">
        <div className="row align-items-center">
          <div className="col-lg-6">
            <ul className="top-header-information">
              <li>
                <i className="bx bx-envelope" />
                <a href="mailto:support@sayettecreditunion.com">
                  <span>support@sayettecreditunion.com</span>
                </a>
              </li>
            </ul>
          </div>

          <div className="col-lg-6">
            <ul className="top-header-others">
              <li className="languages-list">
                <select
                  value={lang}
                  onChange={e => setLang(e.target.value as LangCode)}
                  style={{ cursor: 'pointer' }}
                >
                  {LANGUAGES.map(l => (
                    <option key={l.code} value={l.code}>
                      {l.label}
                    </option>
                  ))}
                </select>
              </li>
              <li>
                <i className="bx bx-user" />
                <a href={`${WEB_APP_URL}/login`}>{t.signIn}</a>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}
