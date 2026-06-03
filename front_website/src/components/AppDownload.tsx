import { useLanguage } from '../context/LanguageContext'

export default function AppDownload() {
  const { t } = useLanguage()
  const handleStore = (store: string) => alert(`${store} — ${t.comingSoon}`)

  return (
    <section className="app-area ptb-100">
      <div className="container">
        <div className="row align-items-center">
          <div className="col-lg-6">
            <div className="app-content">
              <h3>{t.appHeading}</h3>
            </div>
          </div>
          <div className="col-lg-6">
            <div className="app-btn">
              <button className="app-store-btn" onClick={() => handleStore(t.appStore)}>
                <i className="flaticon-apple" />
                {t.downloadOn}
                <span>{t.appStore}</span>
              </button>
              <button className="play-store-btn" onClick={() => handleStore(t.googlePlay)}>
                <i className="flaticon-google-play" />
                {t.downloadOn}
                <span>{t.googlePlay}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
