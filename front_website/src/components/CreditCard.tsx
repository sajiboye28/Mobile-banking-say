import { useLanguage } from '../context/LanguageContext'

const CARD_FEATURES_EN = [
  'Standard credit cards', 'Rewards credit cards', 'Charge cards',
  'Subprime credit cards', 'Limited purpose cards',
  'Balance transfer credit cards', 'Student credit cards',
  'Secured credit cards', 'Prepaid cards', 'Business credit cards',
]

export default function CreditCard() {
  const { t } = useLanguage()
  return (
    <section className="credit-card-area bg-ffffff">
      <div className="container">
        <div className="row align-items-center">
          <div className="col-lg-7">
            <div className="credit-card-content">
              <span>{t.creditCardSpan}</span>
              <h3>{t.creditCardHeading}</h3>
              <p>{t.creditCardP}</p>
              <ul className="credit-card-features">
                {CARD_FEATURES_EN.map(f => (
                  <li key={f}><i className="flaticon-checkmark" /> {f}</li>
                ))}
              </ul>
            </div>
          </div>
          <div className="col-lg-5">
            <div className="credit-card-image-slider">
              <div className="credit-card-image">
                <img src="/assets/img/credit-card/credit-card-2.png" alt="STCU Credit Card" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
