import { useCounter } from '../hooks/useCounter'
import { useLanguage } from '../context/LanguageContext'

interface StatProps { target: number; label: string }

function StatItem({ target, label }: StatProps) {
  const { count, ref } = useCounter(target)
  return (
    <div className="col-lg-3 col-md-6 col-sm-6">
      <div className="single-fun-fact">
        <h3>
          <span ref={ref as React.RefObject<HTMLSpanElement>} className="odometer">
            {count.toLocaleString()}
          </span>
        </h3>
        <p>{label}</p>
      </div>
    </div>
  )
}

export default function FunFacts() {
  const { t } = useLanguage()
  return (
    <section className="fun-facts-area ptb-100">
      <div className="container">
        <div className="section-title">
          <span>{t.whyChooseUs}</span>
          <h2>{t.whyChooseSubtitle}</h2>
        </div>
        <div className="fun-facts-inner">
          <div className="row">
            <StatItem target={358412} label={t.happyCustomers} />
            <StatItem target={25}     label={t.yearsInBanking} />
            <StatItem target={2545}   label={t.ourBranches} />
            <StatItem target={54285}  label={t.successfullyWorks} />
          </div>
        </div>
      </div>
    </section>
  )
}
