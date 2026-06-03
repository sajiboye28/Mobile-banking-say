export type LangCode = 'en' | 'ar' | 'de' | 'pt' | 'zh'

export interface Translations {
  // Top header
  signIn: string
  // Navbar
  home: string
  aboutUs: string
  openAccount: string
  getStarted: string
  // Hero
  heroTitle: string
  heroSubtitle: string
  // About
  aboutSpan: string
  aboutHeading: string
  aboutP1: string
  aboutP2: string
  aboutBtn: string
  // Fun facts
  whyChooseUs: string
  whyChooseSubtitle: string
  happyCustomers: string
  yearsInBanking: string
  ourBranches: string
  successfullyWorks: string
  // Protect
  protectSpan: string
  protectHeading: string
  protectSubtitle: string
  protectItem1: string
  protectItem2: string
  protectItem3: string
  // Services
  servicesSpan: string
  servicesHeading: string
  mobileBanking: string
  creditCards: string
  securePayment: string
  savingAccount: string
  businessBanking: string
  personalSavings: string
  personalLoans: string
  businessLoans: string
  // Banking section
  bankingSpan: string
  bankingHeading: string
  bankingP: string
  bankingLi1: string
  bankingLi2: string
  bankingLi3: string
  // Credit card
  creditCardSpan: string
  creditCardHeading: string
  creditCardP: string
  // How to open
  howToOpenSpan: string
  howToOpenHeading: string
  step1: string
  step2: string
  step3: string
  openAccountNow: string
  // App
  appHeading: string
  downloadOn: string
  appStore: string
  googlePlay: string
  comingSoon: string
  // Subscribe
  subscribeSpan: string
  subscribeHeading: string
  subscribePlaceholder: string
  subscribeBtn: string
  subscribeSuccess: string
  subscribeError: string
  // Footer
  contact: string
  quickLinks: string
  footerDisclaimer: string
  // Copyright
  allRightsReserved: string
}

export const translations: Record<LangCode, Translations> = {
  en: {
    signIn: 'Sign In',
    home: 'Home',
    aboutUs: 'About Us',
    openAccount: 'Open Account',
    getStarted: 'Get Started',
    heroTitle: 'How we can help you achieve your goals',
    heroSubtitle: 'An international account to send money to over 60 countries around the world, up to 7× cheaper.',
    aboutSpan: 'About STCU',
    aboutHeading: 'We operate our banking services in many countries around the world.',
    aboutP1: 'The story of STCU is one of commitment started by our founders — an intense dedication to focusing on the customer above all else. This philosophy has remained the same during our growth from a small bank to a network of community-focused regional banks able to provide a complete range of financial services.',
    aboutP2: 'Staying true to these principles has been the common thread throughout our history. We will always be active and involved members of the communities we serve and we will work to put the needs of our customers first — "People helping people find financial solutions for life."',
    aboutBtn: 'Our Services',
    whyChooseUs: 'Why choose us',
    whyChooseSubtitle: 'Our bank has been providing services to its customers for almost 25 years.',
    happyCustomers: 'Happy customers',
    yearsInBanking: 'Years in banking',
    ourBranches: 'Our branches',
    successfullyWorks: 'Successfully works',
    protectSpan: 'Protect your money',
    protectHeading: "We make every effort to ensure that our customers' money is well protected.",
    protectSubtitle: 'The Reliable, Cheap & Fastest Way To Send Money Abroad.',
    protectItem1: 'Security in bank',
    protectItem2: 'Investments best in class',
    protectItem3: 'Secure watch asset',
    servicesSpan: 'Banking services',
    servicesHeading: 'Our bank has been providing various banking services to our customers.',
    mobileBanking: 'Mobile banking',
    creditCards: 'Credit cards',
    securePayment: 'Secure payment',
    savingAccount: 'Saving account',
    businessBanking: 'Business banking',
    personalSavings: 'Personal savings',
    personalLoans: 'Personal loans',
    businessLoans: 'Business loans',
    bankingSpan: 'Business banking',
    bankingHeading: 'We operate our banking services in many countries around the world',
    bankingP: 'Reach further, achieve more. We offer business banking solutions in numerous countries, helping you expand your reach and power your international ambitions.',
    bankingLi1: 'Simple account opening form. Open a business account from anywhere around the world.',
    bankingLi2: 'Our cards work. With STCU Mastercard, you can pay anywhere.',
    bankingLi3: 'Our customer service works around the clock, always here to attend to your questions.',
    creditCardSpan: 'Credit cards facility',
    creditCardHeading: 'We provide all the credit card facilities to our customers.',
    creditCardP: 'We provide customers with a variety of credit cards based on the convenience of work.',
    howToOpenSpan: 'How to open an account',
    howToOpenHeading: 'You can easily open a bank account by following some rules below.',
    step1: 'Personal details',
    step2: 'Identification',
    step3: 'Address information',
    openAccountNow: 'Open Account Now',
    appHeading: 'Download our App to get all kinds of banking benefits from anywhere',
    downloadOn: 'Download on',
    appStore: 'App Store',
    googlePlay: 'Google Play',
    comingSoon: 'Coming soon! Stay tuned.',
    subscribeSpan: 'Get Started Instantly!',
    subscribeHeading: 'Get Only New Updates from this Newsletter',
    subscribePlaceholder: 'Enter your email',
    subscribeBtn: 'Subscribe',
    subscribeSuccess: 'Thank you for subscribing!',
    subscribeError: 'Please enter a valid email address.',
    contact: 'Contact',
    quickLinks: 'Quick Links',
    footerDisclaimer: 'Investments and Insurance Products: Not a Deposit | Not Guaranteed by the Bank or its Affiliates | Not FDIC Insured | Not Insured by Any Federal Government Agency | May Go Down in Value.',
    allRightsReserved: 'All Rights Reserved by',
  },

  ar: {
    signIn: 'تسجيل الدخول',
    home: 'الرئيسية',
    aboutUs: 'من نحن',
    openAccount: 'فتح حساب',
    getStarted: 'ابدأ الآن',
    heroTitle: 'كيف يمكننا مساعدتك في تحقيق أهدافك',
    heroSubtitle: 'حساب دولي لإرسال الأموال إلى أكثر من 60 دولة حول العالم، بتكلفة أقل بـ 7 مرات.',
    aboutSpan: 'عن STCU',
    aboutHeading: 'نقدم خدماتنا المصرفية في دول عديدة حول العالم.',
    aboutP1: 'قصة STCU هي قصة التزام بدأها مؤسسونا — تفانٍ شديد في التركيز على العميل فوق كل شيء.',
    aboutP2: 'البقاء وفياً لهذه المبادئ كان الخيط المشترك طوال تاريخنا. سنكون دائماً أعضاء نشطين ومشاركين في المجتمعات التي نخدمها.',
    aboutBtn: 'خدماتنا',
    whyChooseUs: 'لماذا تختارنا',
    whyChooseSubtitle: 'يقدم بنكنا خدماته لعملائه منذ ما يقارب 25 عاماً.',
    happyCustomers: 'عملاء سعداء',
    yearsInBanking: 'سنوات في الخدمة المصرفية',
    ourBranches: 'فروعنا',
    successfullyWorks: 'أعمال ناجحة',
    protectSpan: 'احمِ أموالك',
    protectHeading: 'نبذل كل جهد لضمان حماية أموال عملائنا.',
    protectSubtitle: 'الطريقة الموثوقة والرخيصة والأسرع لإرسال الأموال إلى الخارج.',
    protectItem1: 'الأمان في البنك',
    protectItem2: 'استثمارات من الدرجة الأولى',
    protectItem3: 'رقابة آمنة على الأصول',
    servicesSpan: 'الخدمات المصرفية',
    servicesHeading: 'يقدم بنكنا خدمات مصرفية متنوعة لعملائنا.',
    mobileBanking: 'الخدمات المصرفية عبر الهاتف',
    creditCards: 'بطاقات الائتمان',
    securePayment: 'دفع آمن',
    savingAccount: 'حساب توفير',
    businessBanking: 'الخدمات المصرفية للأعمال',
    personalSavings: 'مدخرات شخصية',
    personalLoans: 'قروض شخصية',
    businessLoans: 'قروض تجارية',
    bankingSpan: 'الخدمات المصرفية للأعمال',
    bankingHeading: 'نقدم خدماتنا المصرفية في دول عديدة حول العالم',
    bankingP: 'الوصول إلى أبعد، وتحقيق المزيد. نقدم حلول مصرفية للأعمال في دول عديدة.',
    bankingLi1: 'نموذج فتح حساب بسيط. افتح حساباً تجارياً من أي مكان في العالم.',
    bankingLi2: 'بطاقاتنا تعمل. مع بطاقة STCU ماستركارد، يمكنك الدفع في أي مكان.',
    bankingLi3: 'خدمة العملاء لدينا تعمل على مدار الساعة.',
    creditCardSpan: 'مرفق بطاقات الائتمان',
    creditCardHeading: 'نوفر جميع تسهيلات بطاقات الائتمان لعملائنا.',
    creditCardP: 'نوفر للعملاء مجموعة متنوعة من بطاقات الائتمان.',
    howToOpenSpan: 'كيفية فتح حساب',
    howToOpenHeading: 'يمكنك بسهولة فتح حساب مصرفي باتباع بعض القواعد أدناه.',
    step1: 'البيانات الشخصية',
    step2: 'التعريف',
    step3: 'معلومات العنوان',
    openAccountNow: 'افتح حساباً الآن',
    appHeading: 'حمّل تطبيقنا للاستفادة من جميع المزايا المصرفية من أي مكان',
    downloadOn: 'تحميل من',
    appStore: 'متجر التطبيقات',
    googlePlay: 'جوجل بلاي',
    comingSoon: 'قريباً! ترقب الإطلاق.',
    subscribeSpan: 'ابدأ الآن فوراً!',
    subscribeHeading: 'احصل على آخر التحديثات من النشرة الإخبارية',
    subscribePlaceholder: 'أدخل بريدك الإلكتروني',
    subscribeBtn: 'اشترك',
    subscribeSuccess: 'شكراً لاشتراكك!',
    subscribeError: 'الرجاء إدخال عنوان بريد إلكتروني صحيح.',
    contact: 'تواصل معنا',
    quickLinks: 'روابط سريعة',
    footerDisclaimer: 'منتجات الاستثمار والتأمين: ليست وديعة | غير مضمونة من البنك أو الشركات التابعة له | غير مؤمن عليها من FDIC.',
    allRightsReserved: 'جميع الحقوق محفوظة لـ',
  },

  de: {
    signIn: 'Anmelden',
    home: 'Startseite',
    aboutUs: 'Über uns',
    openAccount: 'Konto eröffnen',
    getStarted: 'Loslegen',
    heroTitle: 'Wie wir Ihnen helfen können, Ihre Ziele zu erreichen',
    heroSubtitle: 'Ein internationales Konto, um Geld in über 60 Länder weltweit zu senden – bis zu 7-mal günstiger.',
    aboutSpan: 'Über STCU',
    aboutHeading: 'Wir betreiben unsere Bankdienstleistungen in vielen Ländern weltweit.',
    aboutP1: 'Die Geschichte der STCU ist eine Geschichte des Engagements, die von unseren Gründern begonnen wurde — eine intensive Hingabe, den Kunden über alles zu stellen.',
    aboutP2: 'Dieser Grundsatz ist der gemeinsame Faden in unserer Geschichte. Wir werden immer aktive Mitglieder der Gemeinschaften sein, denen wir dienen.',
    aboutBtn: 'Unsere Dienste',
    whyChooseUs: 'Warum uns wählen',
    whyChooseSubtitle: 'Unsere Bank bietet ihren Kunden seit fast 25 Jahren Dienstleistungen an.',
    happyCustomers: 'Zufriedene Kunden',
    yearsInBanking: 'Jahre im Bankwesen',
    ourBranches: 'Unsere Filialen',
    successfullyWorks: 'Erfolgreiche Abschlüsse',
    protectSpan: 'Schützen Sie Ihr Geld',
    protectHeading: 'Wir unternehmen alles, um das Geld unserer Kunden gut zu schützen.',
    protectSubtitle: 'Der zuverlässige, günstige und schnellste Weg, Geld ins Ausland zu senden.',
    protectItem1: 'Sicherheit in der Bank',
    protectItem2: 'Investitionen der Spitzenklasse',
    protectItem3: 'Sichere Vermögensüberwachung',
    servicesSpan: 'Bankdienstleistungen',
    servicesHeading: 'Unsere Bank bietet unseren Kunden verschiedene Bankdienstleistungen an.',
    mobileBanking: 'Mobile Banking',
    creditCards: 'Kreditkarten',
    securePayment: 'Sicheres Bezahlen',
    savingAccount: 'Sparkonto',
    businessBanking: 'Geschäftsbanking',
    personalSavings: 'Persönliche Ersparnisse',
    personalLoans: 'Persönliche Kredite',
    businessLoans: 'Geschäftskredite',
    bankingSpan: 'Geschäftsbanking',
    bankingHeading: 'Wir betreiben unsere Bankdienstleistungen in vielen Ländern weltweit',
    bankingP: 'Weiter reichen, mehr erreichen. Wir bieten Geschäftsbanking-Lösungen in zahlreichen Ländern an.',
    bankingLi1: 'Einfaches Kontoeröffnungsformular. Eröffnen Sie ein Geschäftskonto von überall auf der Welt.',
    bankingLi2: 'Unsere Karten funktionieren. Mit der STCU Mastercard können Sie überall bezahlen.',
    bankingLi3: 'Unser Kundenservice ist rund um die Uhr für Sie da.',
    creditCardSpan: 'Kreditkarteneinrichtungen',
    creditCardHeading: 'Wir bieten unseren Kunden alle Kreditkartenmöglichkeiten an.',
    creditCardP: 'Wir bieten Kunden eine Vielzahl von Kreditkarten basierend auf Bequemlichkeit.',
    howToOpenSpan: 'So eröffnen Sie ein Konto',
    howToOpenHeading: 'Sie können einfach ein Bankkonto eröffnen, indem Sie einige Regeln befolgen.',
    step1: 'Persönliche Daten',
    step2: 'Identifizierung',
    step3: 'Adressinformationen',
    openAccountNow: 'Jetzt Konto eröffnen',
    appHeading: 'Laden Sie unsere App herunter, um überall Bankvorteile zu genießen',
    downloadOn: 'Herunterladen bei',
    appStore: 'App Store',
    googlePlay: 'Google Play',
    comingSoon: 'Demnächst verfügbar!',
    subscribeSpan: 'Sofort loslegen!',
    subscribeHeading: 'Erhalten Sie nur neue Updates aus diesem Newsletter',
    subscribePlaceholder: 'Ihre E-Mail-Adresse',
    subscribeBtn: 'Abonnieren',
    subscribeSuccess: 'Danke für Ihr Abonnement!',
    subscribeError: 'Bitte geben Sie eine gültige E-Mail-Adresse ein.',
    contact: 'Kontakt',
    quickLinks: 'Schnelllinks',
    footerDisclaimer: 'Anlage- und Versicherungsprodukte: Keine Einlage | Nicht von der Bank garantiert | Nicht FDIC-versichert | Kann an Wert verlieren.',
    allRightsReserved: 'Alle Rechte vorbehalten bei',
  },

  pt: {
    signIn: 'Entrar',
    home: 'Início',
    aboutUs: 'Sobre nós',
    openAccount: 'Abrir conta',
    getStarted: 'Começar',
    heroTitle: 'Como podemos ajudá-lo a alcançar seus objetivos',
    heroSubtitle: 'Uma conta internacional para enviar dinheiro para mais de 60 países em todo o mundo, até 7× mais barato.',
    aboutSpan: 'Sobre a STCU',
    aboutHeading: 'Operamos nossos serviços bancários em muitos países ao redor do mundo.',
    aboutP1: 'A história da STCU é de comprometimento iniciado pelos nossos fundadores — uma dedicação intensa em focar no cliente acima de tudo.',
    aboutP2: 'Manter-se fiel a esses princípios tem sido o fio condutor de toda a nossa história. Sempre seremos membros ativos das comunidades que servimos.',
    aboutBtn: 'Nossos Serviços',
    whyChooseUs: 'Por que nos escolher',
    whyChooseSubtitle: 'Nosso banco vem prestando serviços aos clientes há quase 25 anos.',
    happyCustomers: 'Clientes satisfeitos',
    yearsInBanking: 'Anos no setor bancário',
    ourBranches: 'Nossas agências',
    successfullyWorks: 'Trabalhos concluídos',
    protectSpan: 'Proteja seu dinheiro',
    protectHeading: 'Fazemos todos os esforços para garantir que o dinheiro dos nossos clientes esteja bem protegido.',
    protectSubtitle: 'A forma confiável, barata e mais rápida de enviar dinheiro ao exterior.',
    protectItem1: 'Segurança no banco',
    protectItem2: 'Investimentos de primeira classe',
    protectItem3: 'Monitoramento seguro de ativos',
    servicesSpan: 'Serviços bancários',
    servicesHeading: 'Nosso banco oferece vários serviços bancários aos nossos clientes.',
    mobileBanking: 'Banco móvel',
    creditCards: 'Cartões de crédito',
    securePayment: 'Pagamento seguro',
    savingAccount: 'Conta poupança',
    businessBanking: 'Banco empresarial',
    personalSavings: 'Poupança pessoal',
    personalLoans: 'Empréstimos pessoais',
    businessLoans: 'Empréstimos empresariais',
    bankingSpan: 'Banco empresarial',
    bankingHeading: 'Operamos nossos serviços bancários em muitos países ao redor do mundo',
    bankingP: 'Chegue mais longe, conquiste mais. Oferecemos soluções bancárias para empresas em vários países.',
    bankingLi1: 'Formulário de abertura de conta simples. Abra uma conta empresarial de qualquer lugar do mundo.',
    bankingLi2: 'Nossos cartões funcionam. Com o Mastercard STCU, você pode pagar em qualquer lugar.',
    bankingLi3: 'Nosso atendimento ao cliente funciona 24 horas, sempre aqui para atender às suas dúvidas.',
    creditCardSpan: 'Facilidades de cartão de crédito',
    creditCardHeading: 'Oferecemos todas as facilidades de cartão de crédito aos nossos clientes.',
    creditCardP: 'Oferecemos aos clientes uma variedade de cartões de crédito.',
    howToOpenSpan: 'Como abrir uma conta',
    howToOpenHeading: 'Você pode abrir uma conta bancária facilmente seguindo algumas regras abaixo.',
    step1: 'Dados pessoais',
    step2: 'Identificação',
    step3: 'Informações de endereço',
    openAccountNow: 'Abrir conta agora',
    appHeading: 'Baixe nosso App para obter todos os tipos de benefícios bancários em qualquer lugar',
    downloadOn: 'Baixar na',
    appStore: 'App Store',
    googlePlay: 'Google Play',
    comingSoon: 'Em breve! Fique ligado.',
    subscribeSpan: 'Comece agora mesmo!',
    subscribeHeading: 'Receba apenas novas atualizações desta newsletter',
    subscribePlaceholder: 'Digite seu e-mail',
    subscribeBtn: 'Assinar',
    subscribeSuccess: 'Obrigado por assinar!',
    subscribeError: 'Por favor insira um endereço de e-mail válido.',
    contact: 'Contato',
    quickLinks: 'Links rápidos',
    footerDisclaimer: 'Produtos de Investimento e Seguro: Não é um Depósito | Não Garantido pelo Banco ou suas Afiliadas | Não Segurado pelo FDIC.',
    allRightsReserved: 'Todos os direitos reservados por',
  },

  zh: {
    signIn: '登录',
    home: '首页',
    aboutUs: '关于我们',
    openAccount: '开户',
    getStarted: '立即开始',
    heroTitle: '我们如何帮助您实现目标',
    heroSubtitle: '一个国际账户，可向全球60多个国家汇款，费用低至7倍。',
    aboutSpan: '关于 STCU',
    aboutHeading: '我们在全球许多国家运营银行服务。',
    aboutP1: 'STCU 的故事是创始人坚守承诺的故事 — 专注于以客户为中心的强烈奉献精神。',
    aboutP2: '坚守这些原则是我们历史的主线。我们将始终是所服务社区的积极成员。',
    aboutBtn: '我们的服务',
    whyChooseUs: '为什么选择我们',
    whyChooseSubtitle: '我们的银行为客户提供服务已近25年。',
    happyCustomers: '满意客户',
    yearsInBanking: '银行业年数',
    ourBranches: '我们的分支机构',
    successfullyWorks: '成功案例',
    protectSpan: '保护您的资金',
    protectHeading: '我们竭尽全力确保客户资金得到妥善保护。',
    protectSubtitle: '向海外汇款最可靠、最便宜、最快捷的方式。',
    protectItem1: '银行安全',
    protectItem2: '一流投资',
    protectItem3: '安全资产监控',
    servicesSpan: '银行服务',
    servicesHeading: '我们的银行为客户提供各种银行服务。',
    mobileBanking: '手机银行',
    creditCards: '信用卡',
    securePayment: '安全支付',
    savingAccount: '储蓄账户',
    businessBanking: '企业银行',
    personalSavings: '个人储蓄',
    personalLoans: '个人贷款',
    businessLoans: '企业贷款',
    bankingSpan: '企业银行',
    bankingHeading: '我们在全球许多国家运营银行服务',
    bankingP: '更远触达，成就更多。我们在众多国家提供企业银行解决方案。',
    bankingLi1: '简单的开户表格。从世界任何地方开立企业账户。',
    bankingLi2: '我们的卡正常使用。使用 STCU 万事达卡，您可以在任何地方支付。',
    bankingLi3: '我们的客户服务全天候运营，随时解答您的问题。',
    creditCardSpan: '信用卡设施',
    creditCardHeading: '我们为客户提供所有信用卡便利服务。',
    creditCardP: '我们根据工作便利性为客户提供各种信用卡。',
    howToOpenSpan: '如何开户',
    howToOpenHeading: '您可以按照以下规则轻松开立银行账户。',
    step1: '个人信息',
    step2: '身份证明',
    step3: '地址信息',
    openAccountNow: '立即开户',
    appHeading: '下载我们的应用程序，随时随地享受各种银行福利',
    downloadOn: '下载于',
    appStore: 'App Store',
    googlePlay: 'Google Play',
    comingSoon: '即将推出！敬请期待。',
    subscribeSpan: '立即开始！',
    subscribeHeading: '仅获取本通讯的最新更新',
    subscribePlaceholder: '请输入您的电子邮件',
    subscribeBtn: '订阅',
    subscribeSuccess: '感谢您的订阅！',
    subscribeError: '请输入有效的电子邮件地址。',
    contact: '联系我们',
    quickLinks: '快速链接',
    footerDisclaimer: '投资和保险产品：非存款 | 不受银行或其附属机构担保 | 不受FDIC保险 | 可能贬值。',
    allRightsReserved: '版权所有',
  },
}
