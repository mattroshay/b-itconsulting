class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :about, :contact, :competences ]

  def home
    @projects = [
      { image: "Passeport_BioMétrique_2.jpg_yhreja", title: "Projet Passeport Biométrique", text: "Coordination complète sur la région parisienne, incluant les phases de test, présentation aux élus locaux et au préfet, transfert de données, et délivrance officielle du premier passeport biométrique en présence de la ministre de l’Intérieur." },
      { image: "VPN_cubkdx", title: "VPN Agirc-Arrco", text: "Assistance et résolution des problématiques de connexion et navigation lors de la mise en place d’un VPN durant le confinement lié à la Covid-19." },
      { image: "website_2_btrsis", title: "Wyze Academy", text: "Supervision de la conception et du développement du site, gestion des équipes de designers et développeurs, suivi des tâches via JIRA, et mise en ligne du centre de formation Wyze Academy." }
    ]

    @testimonies = [
      { image: "Bertrand_DETRE_bzbwee", name: "Bertrand DETRE", testimony: "Benoît a vite compris et s'est très bien adapté à son nouvel environnement de travail. C'était un vrai plaisir de collaborer avec lui : il a été d'une aide précieuse et a su toujours communiquer avec les dirigeants.
      Je recommande de travailler avec lui : il se montrera investi -en tant que chef de projet digital- et loyal pour votre entreprise."},
      { image: "Ferrat_sdsrzq", name: "Francois FERRAT", testimony: "Organisé, sens des priorités, gestion de la pression, respect de la hiérarchie, large faculté d'adaptation, certes réactif sans omettre sa proactivité."},
      { image: "alexia_k2ueok", name: "Alexia ONG", testimony: "C'est avec un grand plaisir que je recommande chaleureusement Benoît pour toute opportunité professionnelle. Durant notre collaboration chez Computacenter, Benoît a fait preuve d'un grand professionnalisme, d'une expertise technique solide et d'un engagement exemplaire durant sa mission.
      Son analyse et ses conseils techniques ont permis de trouver des solutions aux difficultés rencontrées.
      Il se distingue notamment par son fort esprit d'équipe, qui permet de réussir les objectifs fixés dans une ambiance de travail harmonieuse. Il se rend toujours disponible pour aider ses collègues. Ce qui est fort appréciable.
      Sa bonne humeur, sa fiabilité et son attitude positive font de lui un atout précieux pour toute organisation et future équipe."},
      { image: "https://res.cloudinary.com/roshaym/image/upload/w_1000,c_fill,ar_1:1,g_auto,r_max,b_rgb:262c35/v1748270837/Anne_BERTINETTI_rjzuyn.jpg", name: "Anne BERTINETTI", testimony: "Anne BERTINETTI, Chef du département Gestion des Ressources de la Direction de la Sécurité de l'Aviation Civile Sud-Ouest, atteste que Monsieur Benoît MARFANY, a rempli avec sérieux sa mission dans nos services du 1er juin 2015 au 31 mars 2016 en tant qu’administrateur Système.
      M. MARFANY, disponible, possède de bonnes qualités professionnelles et a donné entière satisfaction sur son poste."},
      { image: "Flavien_villant_lbtcon", name: "Flavien VILLANT", testimony: "Monsieur Marfany Benoit à travaillé dans notre société, ITE, du Groupe Alliaserv, en tant qu’Administrateur système et réseaux, de juin à septembre 2012.
      Dans le cadre de cette fonction, Monsieur Marfany a su, durant tout le temps qu’il a passé chez nous, faire preuve de professionnalisme et de sérieux.
      En outre, son travail s’est avéré de très bonne qualité.
      Son sens des responsabilités lui permet de s’adapter très facilement aux nouveaux environnements de travail et sa maitrise des systèmes informatiques lui permet de proposer des solutions adaptées aux besoins des utilisateurs."}
    ]
  end

  def about
    @experiences = [
      {company: "DCS EASYWARE", duration: "2019 à ce jour", url: "https://www.dcsit-group.com", description: "<u><strong>Administrateur Système Savencia - Septembre 2024:</strong></u>
        Dans le cadre de ma mission, j'ai assuré <strong>le support fonctionnel</strong> pour un parc d'environ 13 000 salariés, en travaillant en 100 % télétravail.

        Mes responsabilités comprenaient l'émission d'appels pour <strong>la résolution des incidents, la gestion des activités liées à Citrix, Azure, Intune, et le support des systèmes Windows 10, 11 et Windows Server 2019.</strong>

        Cette approche m'a permis de garantir une gestion des serveurs tout en maintenant une communication fluide avec les équipes.

        <u><strong>Administrateur Système
        Groupe Synergie - Juin et Juillet 2024:</strong></u>
        Dans le cadre de ma mission, <strong>j'ai été chargé de l'administration, du support de niveau 3, et de la gestion pour un parc</strong> d'environ 2000 salariés dans les différents environnements <strong>Windows, Cloud azure et Intune.</strong>

        Je m’occupais également de <strong>l'analyse des tickets</strong> pour garantir un service de qualité et <strong>une résolution rapide des incidents</strong>, contribuant ainsi à l'efficacité opérationnelle de l'organisation.

        <u><strong>Technicien Système
        AGIRC-ARRCO - Décembre 2019 à Septembre 2023:</strong></u>
        Dans le cadre de ma mission, j'ai <strong>fourni une assistance utilisateur et assuré la supervision ainsi que la gestion de projets.</strong>

        J'ai également <strong>géré des problématiques</strong> en collaboration avec les administrateurs système et réseau, notamment pour des solutions comme <strong>Pulse-Sécure</strong>.

        De plus, j'ai pris en charge <strong>la gestion du parc informatique et des masters postes</strong> pour le site de Gradignan, qui comptait environ 250 personnes.

        Cette expérience m'a permis de développer mes compétences en gestion technique et en communication."},
      {company: "WYZE-ACADEMY", duration: "2024 (Suite formation Chef de projet digital)", url: "https://wyze-academy.com", description: "<u><strong>Chef de projet digital
        Mars 2024 - Mai 2024</u></strong>
        Dans le cadre de ma période en entreprise pour WYZE-ACADEMY en 2024, suite à ma formation de Chef de projet digital chez Digital Campus Paris, j'ai occupé le poste de Chef de projet digital.

        J'ai supervisé le <strong>projet de mise en place d'un site web</strong>, en assurant <strong>la gestion pluridisciplinaire du projet</strong> entre les équipes DESIGN, Marketing et Développeurs, tout en utilisant <strong>les méthodes Agile et Scrum.</strong>

        J'ai également assuré <strong>le suivi du cahier des charges</strong>, animé des <strong>réunions hebdomadaires et rédigé des comptes rendus, la planification des deadlines et la gestion des tâches via Jira</strong> (Confluences) ont été des éléments clés de ma mission, tout comme <strong>la réalisation de rapports sous Canva</stong>, ce qui m'a permis de renforcer mes compétences en gestion de projet."}
    ]
  end

  def contact
  end

  def competences
  end
end
