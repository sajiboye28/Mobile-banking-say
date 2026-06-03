import { WEB_APP_URL } from '../config'
import { useLanguage } from '../context/LanguageContext'

export default function HowToOpen() {
  const { t } = useLanguage()
  return (
    <section className="below-area ptb-100">
      <div className="container-fluid">
        <div className="row">
          <div className="col-lg-6">
            <div className="below-image" />
          </div>
          <div className="col-lg-6">
            <div className="below-content">
              <span>{t.howToOpenSpan}</span>
              <h3>{t.howToOpenHeading}</h3>
              <div className="below-inner-content">
                <div className="number"><span>1</span></div>
                <h4>{t.step1}</h4>
              </div>
              <div className="below-inner-content">
                <div className="number"><span>2</span></div>
                <h4>{t.step2}</h4>
              </div>
              <div className="below-inner-content">
                <div className="number"><span>3</span></div>
                <h4>{t.step3}</h4>
              </div>
              <div className="about-btn" style={{ marginTop: '2rem' }}>
                <a href={`${WEB_APP_URL}/register`} className="default-btn">
                  {t.openAccountNow}
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
