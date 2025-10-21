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
require "cgi"
require "uri"
require "active_support/inflector"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/object/blank"

Article.destroy_all

# Helpers
def drive_download_url(file_id, resourcekey: nil)
  return if file_id.blank?

  url = "https://drive.google.com/uc?export=download&id=#{file_id}"
  url += "&resourcekey=#{CGI.escape(resourcekey)}" if resourcekey.present?
  url
end

def drive_thumbnail_url(file_id, size: 1600, resourcekey: nil)
  return if file_id.blank?

  url = "https://drive.google.com/thumbnail?id=#{file_id}&sz=w#{size}"
  url += "&resourcekey=#{CGI.escape(resourcekey)}" if resourcekey.present?
  url
end

def drive_source?(source)
  str = source.to_s.strip
  return false if str.blank?

  !(str =~ %r{\Ahttps?://} && !str.include?("drive.google"))
end

def extract_drive_identifiers(source)
  str = source.to_s.strip
  return [str, nil] unless str.include?("drive.google")

  uri = URI.parse(str)
  params = CGI.parse(uri.query.to_s)

  file_id = params["id"]&.first
  resourcekey = params["resourcekey"]&.first

  if file_id.blank? && uri.path.present?
    if (match = uri.path.match(%r{/d/([^/]+)}))
      file_id = match[1]
    end
  end

  [file_id.presence || str, resourcekey.presence]
rescue URI::InvalidURIError
  [str, nil]
end

def download_from_url(url)
  response = URI.open(url, "User-Agent" => "Mozilla/5.0")
  data = response.read
  content_type = response.content_type.presence
  [data, content_type]
rescue => e
  warn "Download failed from #{url}: #{e.message}"
  [nil, nil]
end

def prepare_remote_file(source, default_content_type: nil)
  str = source.to_s.strip
  return nil if str.blank?

  data = nil
  content_type = nil

  if drive_source?(str)
    file_id, resourcekey = extract_drive_identifiers(str)

    [drive_download_url(file_id, resourcekey: resourcekey),
     drive_thumbnail_url(file_id, resourcekey: resourcekey)].compact.each do |url|
      data, content_type = download_from_url(url)
      break if data.present?
    end
  elsif str =~ %r{\Ahttps?://}
    data, content_type = download_from_url(str)
  else
    warn "Unsupported remote source: #{str}"
  end

  return nil unless data.present?

  io = StringIO.new(data)
  io.set_encoding('BINARY') if io.respond_to?(:set_encoding)

  {
    io: io,
    content_type: content_type.presence || default_content_type || "application/octet-stream"
  }
end

def filename_from_source(source, fallback)
  str = source.to_s
  return fallback if str.blank? || str !~ %r{\Ahttps?://}

  uri = URI.parse(str)
  candidate = File.basename(uri.path.to_s).presence
  candidate && candidate != "." ? candidate : fallback
rescue URI::InvalidURIError
  fallback
end

def ensure_extension(filename, default_extension)
  return filename if default_extension.nil? || default_extension.empty?

  name = filename.to_s
  name = "file" if name.empty?
  name.include?(".") ? name : "#{name}#{default_extension}"
end

def attach_collection!(record, association:, sources:, default_content_type:, filename_prefix:, default_extension: nil, empty_message:)
  inputs = Array(sources).compact
  return if inputs.empty?

  pending = []

  inputs.each_with_index do |source, idx|
    payload = prepare_remote_file(source, default_content_type: default_content_type)

    if payload
      base_name = if block_given?
                    candidate = yield(source, idx, filename_prefix)
                    candidate.nil? || candidate.to_s.empty? ? "#{filename_prefix}_#{idx}" : candidate
                  else
                    "#{filename_prefix}_#{idx}"
                  end

      pending << payload.merge(filename: ensure_extension(base_name, default_extension))
    else
      warn "Skipped #{association.to_s.singularize} ##{idx + 1} for #{record.title}: source #{source.inspect} could not be fetched"
    end
  end

  attachments = record.public_send(association)

  if pending.any?
    attachments.purge if attachments.attached?
    pending.each { |payload| attachments.attach(payload) }
    puts "→ attached #{pending.size} #{association} for #{record.title}"
  else
    warn empty_message
  end
end

def with_cloudinary_folder_reset
  unless defined?(Cloudinary) && Cloudinary.config.respond_to?(:folder) && Cloudinary.config.respond_to?(:folder=)
    return yield
  end

  previous_folder = Cloudinary.config.folder
  yield
ensure
  Cloudinary.config.folder = previous_folder
end


# Ensure a seed user exists (adjust email/password if needed)
user = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
  u.first_name = "Admin"  # Add this
  u.last_name = "User"
end

ARTICLES = [
  {
    title: "💡 L'IA au service des infrastructures informatiques : une révolution en marche ! 🚀",
    date: Date.new(2025, 2, 17),
    video_file_id: "1JOOPaVNLhUukFU3zlODlpn9EqSD15tUH",
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
    video_file_id: "135pIw-nhD_ZtCG7691QtonHLHxs-SQpa",
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
    video_file_id: "1tkJaHA0TSq7U5g-wy0t3rSygNiFLwAxY",
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
    image_file_id: [
      "1gW4zHlrSVhFgbID9QM6_QvExJCR96YyC",
      "1S414gwkAAbej-HSsAgWaeczpSxaCLmje"
    ],
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
    video_file_id: "1jJc_u7YfGslzGN4b4KbvjcXCXC2orL_u",
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
    media: [
      "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w400-bache-haut-mega-scaled-c8eec8.jpg",
      "https://dvqlxo2m2q99q.cloudfront.net/000_clients/4093735/page/w400-datacenter-3-0b0033.jpg"
    ],
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
    image_file_id: [
        "1U-sg9ttFWB8qxWa_aTD2uqb0tvXiqrcs",
        "1x5dPP5fZHXZHcSkVVUJAdRTHEmlnX2EY",
        "1ehueIeDTMaH-TzbWAgG86NN1vPqGd6i2",
        "1EXfgeSbtQWZzG3tzXKJ-tOrIWcSVPlyJ",
        "1Ovm75DPfnO3rvjxDSTwDA_wzbsDZOIya",
        "1PEVwFRSfuJ5yYTk0hEFLhUfIQUs4XQ45",
        "1Dju6cTmVGW3c87JebnjJLO4EYueTBqUm"
    ],
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


previous_cloudinary_folder = if defined?(Cloudinary) && Cloudinary.config.respond_to?(:folder)
  Cloudinary.config.folder
end

with_cloudinary_folder_reset do
  Article.transaction do
    ARTICLES.each_with_index do |attrs, idx|
      a = Article.find_or_initialize_by(title: attrs[:title], user:)
      a.date    = attrs[:date]
      a.content = attrs[:content]

      # --- Video (Drive preview iframe) ---------------------------------------
      # Accept either a file_id or a full preview URL already in attrs
      if attrs[:video_file_id].present?
        a.video_embed_url = "https://drive.google.com/file/d/#{attrs[:video_file_id]}/preview"
      elsif attrs[:video_embed_url].present?
        a.video_embed_url = attrs[:video_embed_url]
      else
        a.video_embed_url = nil
      end

      a.save!  # save record before attaching blobs

      attach_collection!(
        a,
        association: :images,
        sources: attrs[:image_file_ids] || attrs[:image_files] || attrs[:image_file_id],
        default_content_type: "image/jpeg",
        filename_prefix: "article_#{idx}",
        default_extension: ".jpg",
        empty_message: "No new images attached for #{a.title}; keeping existing attachments"
      ) do |_source, i, prefix|
        "#{prefix}_#{i}"
      end

      attach_collection!(
        a,
        association: :media,
        sources: attrs[:media],
        default_content_type: nil,
        filename_prefix: "article_#{idx}_media",
        default_extension: ".bin",
        empty_message: "No new media attached for #{a.title}; keeping existing attachments"
      ) do |source, i, prefix|
        filename_from_source(source, "#{prefix}_#{i}")
      end
    end
  end
end

if defined?(Cloudinary) && Cloudinary.config.respond_to?(:folder=)
  Cloudinary.config.folder = previous_cloudinary_folder
end

puts "Finished! Created #{Article.count} articles."
