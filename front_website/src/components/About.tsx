import { useLanguage } from '../context/LanguageContext'

export default function About() {
  const { t } = useLanguage()
  return (
    <section className="about-area bg-ffffff ptb-100" id="about">
      <div className="container">
        <div className="row">
          <div className="col-lg-6">
            <div className="about-image" />
          </div>
          <div className="col-lg-6">
            <div className="about-content">
              <span>{t.aboutSpan}</span>
              <h3>{t.aboutHeading}</h3>
              <p>{t.aboutP1}</p>
              <p>{t.aboutP2}</p>
              <div className="about-btn">
                <a href="#services" className="default-btn">{t.aboutBtn}</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
