import { WEB_APP_URL } from '../config'
import { useLanguage } from '../context/LanguageContext'

export default function Footer() {
  const { t } = useLanguage()
  return (
    <section className="footer-area pt-100 pb-70" id="contact">
      <div className="container">
        <div className="row">

          {/* Brand */}
          <div className="col-lg-4 col-sm-6">
            <div className="single-footer-widget">
              <div className="footer-logo">
                <h2><a href="#home">STCU</a></h2>
                <p>{t.footerDisclaimer}</p>
                <ul className="social">
                  <li><a href="https://www.facebook.com/STCUBank/" className="facebook" target="_blank" rel="noopener noreferrer"><i className="bx bxl-facebook" /></a></li>
                  <li><a href="https://twitter.com/STCUbank" className="twitter" target="_blank" rel="noopener noreferrer"><i className="bx bxl-twitter" /></a></li>
                  <li><a href="https://www.instagram.com/STCUBank/" className="pinterest" target="_blank" rel="noopener noreferrer"><i className="bx bxl-instagram" /></a></li>
                  <li><a href="http://www.youtube.com/STCU" className="youtube" target="_blank" rel="noopener noreferrer"><i className="bx bxl-youtube" /></a></li>
                </ul>
              </div>
            </div>
          </div>

          {/* Contact */}
          <div className="col-lg-4 col-sm-6">
            <div className="single-footer-widget">
              <h3>{t.contact}</h3>
              <ul className="footer-contact-info">
                <li>
                  <i className="bx bx-envelope" />
                  <span>Email</span>
                  <a href="mailto:support@sayettecreditunion.com">support@sayettecreditunion.com</a>
                </li>
              </ul>
            </div>
          </div>

          {/* Quick links */}
          <div className="col-lg-4 col-sm-6">
            <div className="single-footer-widget">
              <h3>{t.quickLinks}</h3>
              <ul className="quick-links">
                <li><a href="#home">{t.home}</a></li>
                <li><a href="#about">{t.aboutUs}</a></li>
                <li><a href="#services">{t.servicesSpan}</a></li>
                <li><a href={`${WEB_APP_URL}/login`}>{t.signIn}</a></li>
                <li><a href={`${WEB_APP_URL}/register`}>{t.openAccount}</a></li>
              </ul>
            </div>
          </div>

        </div>
      </div>
    </section>
  )
}
