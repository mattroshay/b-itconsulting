# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding articles…"

require "open-uri"

# --- Helpers ---------------------------------------------------------------

def fetch_io(url)
  URI.open(url)
rescue OpenURI::HTTPError, SocketError, Errno::ECONNRESET, Errno::ETIMEDOUT
  # Retry with browser-y headers (helps with some CDNs)
  URI.open(url, "User-Agent" => "Mozilla/5.0", "Referer" => "https://www.google.com")
end

def ensure_filename(url, content_type)
  base = File.basename(URI.parse(url).path.presence || "file")
  return base if File.extname(base).present? || content_type.to_s.empty?

  case
  when content_type.start_with?("image/jpeg") then "#{base}.jpg"
  when content_type.start_with?("image/png")  then "#{base}.png"
  when content_type.start_with?("image/webp") then "#{base}.webp"
  when content_type.start_with?("image/gif")  then "#{base}.gif"
  when content_type.start_with?("video/mp4")  then "#{base}.mp4"
  else base
  end
end

def attach_url!(record, name, url)
  io        = fetch_io(url)
  ct        = io.content_type.presence || "application/octet-stream"
  filename  = ensure_filename(url, ct)

  record.public_send(name).attach(io: io, filename: filename, content_type: ct)
  blob = record.public_send(name).attachments.last&.blob
  puts "→ attached #{filename} (ct=#{ct}) key=#{blob&.key}"
rescue => e
  warn "× FAILED to attach #{url}: #{e.class} #{e.message}"
end

# Ensure a seed user exists (adjust email/password if needed)
user = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
end

ARTICLES = [
  {
    title: "💡 L'IA au service des infrastructures informatiques : une révolution en marche ! 🚀",
    date: Date.new(2025, 2, 17),
    # media: "https://i.vimeocdn.com/video/1983634618-d113aaf426679dabea940f4832060fd974358b94488429e16078fe21f2734a68-d_295x166",
    content: <<~TEXT
      L'intelligence artificielle (IA) transforme profondément la gestion des infrastructures IT. Découvrez les 6 étapes clés où l'IA joue un rôle essentiel :

      1️⃣ Optimisation des infrastructures : Automatisation des tâches complexes, réduction des coûts, et amélioration de la fiabilité.

      2️⃣ Réseaux intelligents : Surveillance en temps réel, détection des cyberattaques, et optimisation des flux. 🌐

      3️⃣ Cloud computing : Gestion dynamique des ressources, prédictions basées sur les données, et réduction des coûts. ☁️

      4️⃣ Maintenance prédictive : Anticipation des pannes, meilleure disponibilité des services, et équipements plus durables. 🔧

      5️⃣ Cybersécurité renforcée : Détection proactive des menaces et des comportements anormaux pour une sécurité optimale. 🔒

      6️⃣ Pourquoi l'IA est essentielle ? : Pour construire des systèmes robustes, performants, et économiquement viables à l’ère numérique. ✨

      👉 Et vous, comment intégrez-vous l’IA dans vos infrastructures ? Partagez vos expériences en commentaire !

      #IA #Infrastructures #CloudComputing #Cybersécurité #MaintenancePrédictive #InnovationTechnologique #TransformationDigitale #Digitalisation #Technologie #Automatisation #Réseaux
    TEXT
  },
  {
    title: "L’IA, un levier d’innovation en Gironde ! 🚀",
    date: Date.new(2025, 2, 12),
    # media: "https://i.vimeocdn.com/video/1981716356-f954834040330812d35599961cce1fb7ba250229e38d7449bd8a47b246fccbc5-d_295x166",
    content: <<~TEXT
      La Gironde accélère sa transformation numérique avec Bordeaux comme moteur technologique ! L’intelligence artificielle (IA) est au cœur de cette révolution, boostant les entreprises, l’emploi et l’innovation.

      💡 L’IA générative automatise la création de contenus, le développement web et la promotion des secteurs clés comme le vin et le tourisme.
      ⚙️ L’IA interne optimise la gestion d’entreprise, améliore le recrutement et renforce la cybersécurité.
      📈 Résultat ? Un marché de l’emploi en pleine évolution, avec une forte demande pour les experts en IA et des formations adaptées aux nouveaux besoins.
      🌍 Grâce à des pôles comme Bordeaux Technowest et la Cité Numérique, la Gironde devient un hub d’innovation incontournable !

      👉 Et vous, comment voyez-vous l’avenir de l’IA dans votre secteur ? Partagez vos idées en commentaires ! 💬

      #IA #Innovation #Digital #Bordeaux #Gironde #Entreprises #Emploi #Startups #TransformationDigitale #Technologie #MarketingDigital #DéveloppementWeb #Automatisation #FutureOfWork 🚀
    TEXT
  },
  {
    title: "La formation en informatique et numérique en Gironde : Opportunités et Perspectives",
    date: Date.new(2025, 2, 7),
    # media: "https://i.vimeocdn.com/video/1979972951-0d4d489771dc3be776d3440e705ac7cec46f88e9f72208c9bb781c457a6023e0-d_295x166",
    content: <<~TEXT
      Le secteur du numérique est en pleine expansion, et la Gironde s’impose comme un territoire dynamique offrant de nombreuses opportunités de formation. Universités, écoles privées, centres de formation professionnelle : l’offre est variée et s’adapte aussi bien aux étudiants qu’aux professionnels en reconversion.

      ✅ Les formations en informatique proposées par les universités et les écoles privées
      ✅ Les cursus spécialisés en cybersécurité
      ✅ Les opportunités pour les adultes en formation continue ou en reconversion
      ✅ Les événements incontournables comme le Salon Studyrama Bordeaux et Aquitec
      ✅ Le rôle de la French Tech Bordeaux dans l’accompagnement des talents

      Que vous soyez étudiant, professionnel en quête d’évolution ou en reconversion, la Gironde offre une multitude de formations pour vous préparer aux métiers du numérique.

      💡 Découvrez dans notre article toutes les options pour construire votre avenir dans l’informatique !

      #FormationNumérique #InformatiqueGironde #EmploiNumérique #Développeur #Cybersécurité #BordeauxTech #CNAM #FormationAdulte #StudyramaBordeaux #CESIBordeaux #FrenchTechBordeaux #Tech4Good #StartupBordeaux
    TEXT
  },
  {
    title: "L'évolution de l'informatique pour les entreprises girondines depuis les années 2000 et l'impact sur l'emploi",
    date: Date.new(2025, 1, 19),
    # media: "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-capture-decran-2025-01-19-a-213428-604910.png",
    content: <<~TEXT
      L'évolution de l'informatique pour les entreprises en Gironde depuis les années 2000 a été marquée par plusieurs avancées technologiques majeures.
      Au début des années 2000, les entreprises ont commencé à adopter des solutions de bureautique et de gestion de base de données, avec une utilisation croissante de Windows et de Microsoft Office.
      Avec l'essor d'Internet, les entreprises ont progressivement intégré des solutions de commerce électronique et de communication en ligne.
      À partir de la fin des années 2000, la numérisation a pris une nouvelle dimension avec l'adoption du cloud computing, permettant aux entreprises de stocker et de gérer leurs données de manière plus flexible et économique.
      Les technologies de l'information et de la communication (TIC) ont également évolué, avec une utilisation accrue des réseaux sociaux pour la communication et le marketing.
      Depuis les années 2010, l'intelligence artificielle et l'analyse de données sont devenues des outils essentiels pour les entreprises, permettant une prise de décision plus éclairée et une personnalisation accrue des services.
      Enfin, les initiatives locales comme Gironde Numérique ont joué un rôle crucial en soutenant les entreprises dans leur transition numérique et en favorisant l'accès à des infrastructures de haute qualité.

      L'évolution du marché de l'emploi dans l'informatique et le numérique en Gironde depuis les années 2000 a été marquée par plusieurs tendances importantes.Au début des années 2000, l'accent était mis sur les compétences en bureautique et en gestion de base de données. Avec l'essor d'Internet, les entreprises ont commencé à développer des compétences en commerce électronique et en communication en ligne.

      En 2025, la Nouvelle-Aquitaine compte environ 57800 postes
    TEXT
  },
  {
    title: "De l'arpanet à L'internet",
    date: Date.new(2025, 1, 12),
    # media: "https://i.vimeocdn.com/video/1976500719-f62f051f5dca6f8d402ef9ed788a969688032262a0f21253a8f6ceded3f7decf-d_295x166",
    content: <<~TEXT
      Avez-vous déjà réfléchi à l'évolution incroyable d'ARPANET à l'Internet tel que nous le connaissons aujourd'hui ?
      Quelles innovations ont permis cette transformation radicale ?
      Comment les premières connexions ont-elles jeté les bases de notre monde hyperconnecté ?
      Et si nous explorions ensemble les défis et les succès qui ont marqué cette aventure technologique ?
      Ne manquez pas la vidéo suivante, où nous plongerons dans cette fascinante histoire et découvrirons comment chaque étape a façonné notre quotidien numérique !
    TEXT
  },
  {
    title: "Le Datacenter de Gironde Numérique",
    date: Date.new(2025, 1, 12),
    # media: [
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w400-bache-haut-mega-scaled-c8eec8.jpg",
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w400-datacenter-3-0b0033.jpg"
    # ],
    content: <<~TEXT
      Gironde Numérique a mis en place un datacenter souverain et 100 % public, conçu pour garantir la sécurité et l'intégrité des données publiques. Ce centre de données joue un rôle essentiel dans la protection des informations sensibles des collectivités locales, en offrant des solutions de sauvegarde et de gestion des données fiables.

      Sécurité des Données
      Le datacenter de Gironde Numérique permet aux collectivités de protéger leurs données en cas d'incidents majeurs. Grâce à un système de sauvegarde externalisée, les données sont stockées en toute sécurité au sein de la collectivité, avec une copie réalisée chaque soir dans le datacenter. Cela assure non seulement la protection contre le vol ou la dégradation, mais permet également une récupération rapide des données perdues.

      Historique de Sauvegarde
      Les utilisateurs bénéficient d'un historique de sauvegarde qui peut s'étendre de 15 jours à 1 an, garantissant ainsi une flexibilité et une tranquillité d'esprit en matière de gestion des données. Ce service est particulièrement précieux pour les collectivités qui doivent respecter des obligations réglementaires strictes en matière de conservation des données.

      Diagnostic et Installation
      La mise en place du service commence par un diagnostic à distance d’une quinzaine de minutes, suivi de l’intervention d’un technicien pour l’installation du dispositif. Cela permet une intégration rapide et efficace, sans perturber le fonctionnement quotidien des collectivités.

      Conclusion
      En offrant un datacenter local et sécurisé, Gironde Numérique accompagne les collectivités dans leur transition numérique, tout en garantissant la souveraineté des données. Ce service est un pilier essentiel pour une gestion numérique moderne et sécurisée, répondant aux besoins croissants de protection des données dans un monde de plus en plus connecté.
    TEXT
  },
  {
    title: "Cyberattaques en Gironde : Un Alerte Croissante pour les Entreprises",
    date: Date.new(2025, 1, 12),
    # media: [
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-cyberattaque-2-2eea3a.png",
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-cyberattaque-3-2eea3a.png",
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-cyberattaque-4-07a1db.png",
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-cyberattaque-5-20cf06.png",
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-cyberattaque-1-8b5aa9.png",
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-cyberattaque-6-20cf06.png",
    #   "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w1000-cyberattaque-7-20cf06.png"
    # ],
    content: <<~TEXT
      🔒 Introduction

      Les cyberattaques représentent une menace de plus en plus pressante pour les entreprises, et la Gironde n'est pas épargnée. Que ce soit par ransomware, vol de données ou escroqueries en ligne, la vulnérabilité des entreprises locales est en forte augmentation.

      📊 L'Évolution des Cyberattaques

      Au cours des dix dernières années, le nombre de cyberattaques en France a explosé. En 2016, le coût annuel de la cybercriminalité s'élevait à 5,1 milliards de dollars. En 2023, ce chiffre a atteint un alarmant 93,46 milliards de dollars. Les petites et moyennes entreprises girondines sont particulièrement touchées, souvent en raison d'un manque de sensibilisation et de protection.

      💰 Coûts Financiers

      Le coût moyen d'une cyberattaque en France est estimé à 14 720 €, et une entreprise sur huit subit des pertes dépassant les 230 000 €. Les PME, qui représentent 34 % des victimes, doivent faire face à des coûts souvent insurmontables.

      🛡️ Solutions à Mettre en Place

      Il est crucial pour les entreprises de prendre des mesures proactives :

      Former les employés aux risques informatiques.

      Installer des systèmes de détection et de prévention.

      Effectuer des sauvegardes régulières des données.

      🤝 Initiatives Locales

      La Gironde met en œuvre des initiatives pour renforcer la cybersécurité. Le Campus régional de cybersécurité en Nouvelle Aquitaine offre un soutien aux entreprises, tandis que des campagnes de sensibilisation sont menées par la CCI Bordeaux Gironde.

      🚀 Conclusion

      Face à l'augmentation des cyberattaques, renforcer la cybersécurité est essentiel pour protéger nos entreprises et notre économie locale. La collaboration entre entreprises, pouvoirs publics et organismes de cybersécurité sera déterminante pour limiter les risques.

      Restez vigilants et protégez votre entreprise ! 💪🔐

      #CyberSécurité #Gironde #Entreprises #ProtectionDesDonnées
    TEXT
  }
]

Article.transaction do
  ARTICLES.each do |attrs|
    article = Article.find_or_initialize_by(title: attrs[:title], user:)
    article.assign_attributes(date: attrs[:date], content: attrs[:content])
    article.save!

    urls = Array(attrs[:media]).compact
    next if urls.empty?

    # Keep idempotency: replace attachments on reseed
    article.media.purge
    urls.each { |url| attach_url!(article, :media, url) }
  end
end

puts "Finished! Created #{Article.count} articles."
