import { useLanguage } from '../context/LanguageContext'

export default function Copyright() {
  const { t } = useLanguage()
  return (
    <div className="copyright-area">
      <div className="container">
        <div className="copyright-area-content">
          <p>
            Copyright &copy; {new Date().getFullYear()} STCU. {t.allRightsReserved}{' '}
            <a href="#home" target="_blank" rel="noopener noreferrer">
              sayettecreditunion
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}
