import { useState } from 'react'
import { useLanguage } from '../context/LanguageContext'

export default function Subscribe() {
  const { t } = useLanguage()
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [message, setMessage] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setStatus('error')
      setMessage(t.subscribeError)
      return
    }
    setStatus('success')
    setMessage(t.subscribeSuccess)
    setEmail('')
    setTimeout(() => { setStatus('idle'); setMessage('') }, 4000)
  }

  return (
    <section className="subscribe-area ptb-100">
      <div className="container">
        <div className="row align-items-center">
          <div className="col-lg-6">
            <div className="subscribe-content">
              <span>{t.subscribeSpan}</span>
              <h2>{t.subscribeHeading}</h2>
            </div>
          </div>
          <div className="col-lg-6">
            <form
              className={`newsletter-form${status === 'error' ? ' animated shake' : ''}`}
              onSubmit={handleSubmit}
              noValidate
            >
              <input
                type="email"
                className="input-newsletter"
                placeholder={t.subscribePlaceholder}
                value={email}
                onChange={e => setEmail(e.target.value)}
                autoComplete="off"
                required
              />
              <button type="submit">{t.subscribeBtn}</button>
              {message && (
                <div
                  id="validator-newsletter"
                  className={status === 'success' ? 'validation-success' : 'validation-danger'}
                >
                  {message}
                </div>
              )}
            </form>
          </div>
        </div>
      </div>
    </section>
  )
}
