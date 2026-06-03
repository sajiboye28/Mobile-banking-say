import { useLanguage } from '../context/LanguageContext'

export default function Protect() {
  const { t } = useLanguage()
  return (
    <section className="protect-area pb-100">
      <div className="container-fluid">
        <div className="row">
          <div className="col-lg-6">
            <div className="protect-content">
              <span>{t.protectSpan}</span>
              <h3>{t.protectHeading}</h3>
              <p>{t.protectSubtitle}</p>
              <div className="protect-inner-content">
                <div className="number"><span>1</span></div>
                <h4>{t.protectItem1}</h4>
              </div>
              <div className="protect-inner-content">
                <div className="number"><span>2</span></div>
                <h4>{t.protectItem2}</h4>
              </div>
              <div className="protect-inner-content">
                <div className="number"><span>3</span></div>
                <h4>{t.protectItem3}</h4>
              </div>
            </div>
          </div>
          <div className="col-lg-6">
            <div className="protect-image" />
          </div>
        </div>
      </div>
    </section>
  )
}
