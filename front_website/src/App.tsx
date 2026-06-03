import { ThemeProvider } from './context/ThemeContext'
import { LanguageProvider } from './context/LanguageContext'

import Preloader    from './components/Preloader'
import TopHeader   from './components/TopHeader'
import Navbar      from './components/Navbar'
import HeroBanner  from './components/HeroBanner'
import About       from './components/About'
import FunFacts    from './components/FunFacts'
import Protect     from './components/Protect'
import Services    from './components/Services'
import Banking     from './components/Banking'
import CreditCard  from './components/CreditCard'
import HowToOpen   from './components/HowToOpen'
import AppDownload from './components/AppDownload'
import Subscribe   from './components/Subscribe'
import Footer      from './components/Footer'
import Copyright   from './components/Copyright'
import GoTop       from './components/GoTop'
import ThemeToggle from './components/ThemeToggle'

export default function App() {
  return (
    <LanguageProvider>
      <ThemeProvider>
        <Preloader />
        <TopHeader />
        <Navbar />
        <main>
          <HeroBanner />
          <About />
          <FunFacts />
          <Protect />
          <Services />
          <Banking />
          <CreditCard />
          <HowToOpen />
          <AppDownload />
          <Subscribe />
        </main>
        <Footer />
        <Copyright />
        <GoTop />
        <ThemeToggle />
      </ThemeProvider>
    </LanguageProvider>
  )
}
