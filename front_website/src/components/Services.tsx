import { useLanguage } from '../context/LanguageContext'

export default function Services() {
  const { t } = useLanguage()

  const services = [
    { icon: 'flaticon-mobile-banking', title: t.mobileBanking },
    { icon: 'flaticon-credit-card',    title: t.creditCards },
    { icon: 'flaticon-payment-security', title: t.securePayment },
    { icon: 'flaticon-savings',        title: t.savingAccount },
    { icon: 'flaticon-protection',     title: t.businessBanking },
    { icon: 'flaticon-online-banking', title: t.personalSavings },
    { icon: 'flaticon-positive-vote',  title: t.personalLoans },
    { icon: 'flaticon-bank',           title: t.businessLoans },
  ]

  return (
    <section className="services-area bg-transparent pt-100 pb-70" id="services">
      <div className="container">
        <div className="section-title">
          <span>{t.servicesSpan}</span>
          <h2>{t.servicesHeading}</h2>
        </div>
        <div className="row">
          {services.map(s => (
            <div key={s.title} className="col-lg-3 col-md-6">
              <div className="single-services-item">
                <div className="icon"><i className={s.icon} /></div>
                <h3><a href="#services">{s.title}</a></h3>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
