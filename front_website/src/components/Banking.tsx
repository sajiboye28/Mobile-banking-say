import { useLanguage } from '../context/LanguageContext'

export default function Banking() {
  const { t } = useLanguage()
  return (
    <section className="banking-area bg-ffffff pb-100">
      <div className="container-fluid">
        <div className="row">
          <div className="col-lg-6">
            <div className="banking-image-warp" />
          </div>
          <div className="col-lg-6">
            <div className="banking-content">
              <span>{t.bankingSpan}</span>
              <h3>{t.bankingHeading}</h3>
              <p>{t.bankingP}</p>
              <ul className="banking-list">
                <li><i className="flaticon-check" />{t.bankingLi1}</li>
                <li><i className="flaticon-check" />{t.bankingLi2}</li>
                <li><i className="flaticon-check" />{t.bankingLi3}</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
