import { WEB_APP_URL } from '../config'
import { useLanguage } from '../context/LanguageContext'

export default function HeroBanner() {
  const { t } = useLanguage()
  return (
    <div className="main-banner" id="home">
      <div className="main-banner-item banner-item-five">
        <div className="container">
          <div className="main-banner-content">
            <h1>{t.heroTitle}</h1>
            <p>{t.heroSubtitle}</p>
            <div className="banner-btn">
              <a href={`${WEB_APP_URL}/login`} className="default-btn">
                {t.getStarted}
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
