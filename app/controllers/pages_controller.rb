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
      { image: "Flavien_villant_lbtcon", name: "Flavien VILLANT", testimony: "Monsieur Marfany Benoit à travaillé dans notre société, ITE, du Groupe Alliaserv, en tant qu’Administrateur Système et Réseaux, de juin à septembre 2012.
      Dans le cadre de cette fonction, Monsieur Marfany a su, durant tout le temps qu’il a passé chez nous, faire preuve de professionnalisme et de sérieux.
      En outre, son travail s’est avéré de très bonne qualité.
      Son sens des responsabilités lui permet de s’adapter très facilement aux nouveaux environnements de travail et sa maitrise des systèmes informatiques lui permet de proposer des solutions adaptées aux besoins des utilisateurs."}
    ]
  end

  def about
    @experiences1 = [
      {
        company: 'DCS EASYWARE',
        url: 'https://www.dcsit-group.com',
        period: '2019 à ce jour',
        role: 'Administrateur Système
        Savencia – Septembre 2024:',
        details: "Dans le cadre de ma mission, j'ai assuré <strong>le support fonctionnel</strong> pour un parc d'environ 13 000 salariés, en travaillant en 100 % télétravail.

        Mes responsabilités comprenaient l'émission d'appels pour <strong>la résolution des incidents, la gestion des activités liées à Citrix, Azure, Intune, et le support des systèmes Windows 10, 11 et Windows Server 2019.</strong>

        Cette approche m'a permis de garantir une gestion des serveurs tout en maintenant une communication fluide avec les équipes."
      },
      {
        company: 'DCS EASYWARE',
        period: '2019 à ce jour',
        role: 'Administrateur Système
        Groupe Synergie – Juin et Juillet 2024:',
        details: "Dans le cadre de ma mission, j'ai été chargé de <strong>l'administration, du support de niveau 3, et de la gestion pour un parc</strong> d'environ 2000 salariés dans les différents environnements <strong>Windows, Cloud Azure et Intune.</strong>

        Je m’occupais également de <strong>l'analyse des tickets</strong> pour garantir un service de qualité et une <strong>résolution rapide des incidents</strong>, contribuant ainsi à l'efficacité opérationnelle de l'organisation."
      },
      {
        company: 'DCS EASYWARE',
        period: 'Décembre 2019 à Septembre 2023',
        role: 'Technicien Système
        AGIRC-ARRCO: Decembre 2019 à Septembre 2023:',
        details: "Dans le cadre de ma mission, <strong>j'ai fourni une assistance utilisateur et assuré la supervision ainsi que la gestion de projets.</strong>

        J'ai également <strong>géré des problématiques</strong> en collaboration avec les administrateurs système et réseau, notamment pour des solutions comme <strong>Pulse-Sécure</strong>.

        De plus, j'ai pris en charge <strong>la gestion du parc informatique et des masters postes</strong> pour le site de Gradignan (environ 250 personnes).

        Cette expérience m'a permis de développer mes compétences en gestion technique et en communication."
      },
      {
        company: 'WYZE-ACADEMY',
        url: 'https://www.wyze-academy.com',
        period: '2024 (Suite formation Chef de projet digital)',
        role: 'Chef de projet digital
        Mars 2024 – Mai 2024',
        details: "Dans le cadre de ma période en entreprise pour WYZE-ACADEMY en 2024, suite à ma formation de Chef de projet digital chez Digital Campus Paris, j'ai occupé le poste de Chef de projet digital.

        J'ai supervisé le <strong>projet de mise en place d'un site web</strong>, en assurant <strong>la gestion pluridisciplinaire du projet</strong> entre les équipes DESIGN, Marketing et Développeurs, tout en utilisant <strong>les méthodes Agile et Scrum</strong>.

        J'ai également assuré <strong>le suivi du cahier des charges</strong>, animé des <strong>réunions hebdomadaires et rédigé des comptes rendus, la planification des deadlines et la gestion des tâches via Jira</strong> (Confluences) ont été des éléments clés de ma mission, tout comme <strong>la réalisation de rapports sous Canva</strong>, ce qui m'a permis de renforcer mes compétences en gestion de projet."
      },
      {
        company: 'COMPUTACENTER',
        url: 'https://www.computacenter.com/fr-fr',
        period: '2019 - 2011 - 2007',
        role: 'Technicien Système
        AXA / Dassault Aviation - Mars 2019 à Décembre 2019',
        details: "Dans le cadre de la mission, j’avais <strong>la responsabilité du bon suivi du projet</strong>, et assurer <strong>le changement de poste</strong> et <strong>la migration des données.</strong>

        Pour la mission qui concernait Dassault Aviation, <strong>la confidentialité défense</strong> était importante ainsi que <strong>la sécurisation des données.</strong> Chaque poste était configuré avec une clé de cryptage.

        Mon rôle incluait également le <strong>reporting et la documentation des processus</strong>, ainsi que <stong>l'assistance technique et le support utilisateur</strong>, ce qui m'a permis de développer des compétences en gestion de projets informatiques et en communication."
      },
      {
        company: 'COMPUTACENTER',
        period: '2019 - 2011 - 2007',
        role: 'Administrateur Système
        Ministère de la Défense - Octobre 2011 à Janvier 2012',
        details: "Dans le cadre de ma mission j'ai réalisé le <strong>déploiement de serveurs de proximité sous 2012R2</strong>, avec la <strong>virtualisation de plusieurs serveurs sous Hyper-V.</strong>

        J'ai également effectué le <strong>paramétrage des serveurs virtuels</strong> et du réseau, tout en garantissant <strong>la gestion de la sécurité et de la performance des systèmes.</strong>

        Cela m'a permis de renforcer mes compétences techniques en infrastructure."
      },
      {
        company: 'COMPUTACENTER',
        period: '2019 - 2011 - 2007',
        role: 'Technicien Système
        Groupe Manpower - Août 2007 à Mars 2008',
        details: "Dans le cadre de cette mission, j'ai assuré <strong>l'infogérance pour l'ouverture d'une nouvelle agence</strong> ainsi que pour le déménagement d'agences existantes et superviser le déménagement et <strong>la réinstallation de l'ensemble du système d'information.</strong>

        En outre, j'ai réalisé des <strong>tests applicatifs</strong> et fourni <strong>un support technique</strong>, tout en rédigeant <strong>des comptes rendus d'activité.</strong>

        Cette expérience m'a permis de développer mes compétences en gestion de projets et en support technique."
      },
      {
        company: 'ECONOCOM',
        period: '2018',
        url: 'https://www.econocom.com/fr',
        role: 'Technicien Système
        Groupe Engie - Août 2018 à Décembre 2018',
        details: "J’avais la responsabilité de <strong>la gestion de ce projet de déploiement des postes</strong> sous Windows 10.

        J'en ai assuré <strong>la coordination et la gestion du planning</strong> pour les différents sites de la partie sud de la France, tout en m'occupant de <strong>la migration, du changement et de la résolution</strong> des problèmes sur les postes.

        Cela m'a permis de renforcer mes compétences en gestion de projet et en support technique."
      }
    ]
    @experiences2 = [
      {
        company: 'CAPGEMINI Sogeti',
        url: 'https://www.capgemini.com/fr-fr/notre-groupe/nous-connaitre/nos-marques/sogeti/',
        period: '2017',
        role: 'Administrateur Système
        Groupe EDF - Octobre 2017 à Décembre 2017',
        details: "En tant qu'Administrateur Système au sein du groupe EDF, j'ai été responsable de l'administration des serveurs et de la gestion des <strong>incidents de niveau 3.</strong>

        Mon rôle m'a permis de développer des compétences techniques approfondies, notamment en <strong>virtualisation avec VMware (Vsphère, ESXi 6).</strong>

        De plus, j'ai contribué à l'élaboration et à la mise en œuvre du <strong>Plan de Reprise d'Activité (PRA)</strong>, garantissant ainsi la continuité des services en cas de défaillance.

        Cette expérience m'a permis d'acquérir une solide expertise dans la gestion des infrastructures IT et de renforcer mes capacités à résoudre des problèmes complexes."
      },
      {
        company: 'CASTEL-FRERES',
        url: 'https://www.castel-freres.com',
        period: '2016 - 2017',
        role: 'Technicien Système
        Juillet 2016 à Juin 2017',
        details: "Au sein de Castel-Frères, j'étais chargé de fournir un <strong>support de niveau I et II pour les postes de travail</strong>, incluant environ 1200 postes.

        Mon rôle impliquait également <strong>la gestion des serveurs Citrix</strong> via l’interface ainsi qu'une <strong>assistance technique pour les sessions</strong>, supervisant un parc de 72 serveurs.

        De plus, j'ai assuré <strong>la gestion du parc informatique</strong>, ce qui m'a permis de développer des compétences solides en maintenance et en optimisation des systèmes.

        Cette expérience m'a permis d'améliorer la satisfaction des utilisateurs tout en garantissant le bon fonctionnement des infrastructures IT."
      },
      {
        company: 'D.G.A.C',
        url: 'https://www.ecologie.gouv.fr/direction-generale-laviation-civile-dgac-0',
        period: '2015 - 2016',
        role: 'Administrateur Système
        Juin 2015 à Avril 2016',
        details: "Dans le cadre de mon poste d'Administrateur Système, j'avais la responsabilité de <strong>l'administration de 38 serveurs</strong>, assurant leur bon fonctionnement et leur sécurité et de la <strong>sauvegarde via Veeam Backup.</strong>

        J'ai contribué a <strong>des projets de réplication des serveurs</strong>, garantissant la continuité des services et la disponibilité des données et de <strong>l’amélioration de l’infrastructure Système.</strong>

        En parallèle, j'ai fourni un <strong>support utilisateur sur les différents outils informatiques</strong> utilisés par les équipes ainsi que sur le système de navigation aérienne.

        Cette expérience m'a permis d'acquérir une expertise technique solide et de développer mes compétences en administration, gestion de projets et en relation client."
      },
      {
        company: 'SCC – ARIANE GROUP',
        url: 'https://ariane.group/en/',
        period: '2014 - 2015',
        role: 'Coordinateur de projet
        Ariane Group – Octobre 2014 à Avril 2015',
        details: "En tant que Coordinateur de Projet, j'ai supervisé <strong>le déploiement de 600 postes de travail</strong> en collaboration avec une équipe de 6 techniciens.

        Mon rôle impliquait <strong>une étroite collaboration avec le manager de projet</strong> pour garantir le respect des délais et des objectifs fixés.

        Je participais  <strong>aux comités de pilotage (COPIL)</strong> hebdomadaires avec le client, dans le cadre du projet, assurant <strong>une communication efficace</strong> entre toutes les parties prenantes.

        Cette expérience m'a permis de développer mes compétences en gestion d'équipe et en coordination de projet tout en renforçant ma capacité à travailler sous pression."
      }
    ]
      @experiences3 = [
      {
        company: 'CONNIT SAS',
        url: 'https://partners.sigfox.com/companies/connit',
        period: '2013 - 2014',
        role: 'Administrateur Système
        Décembre 2013 à Avril 2014',
        details: "En tant qu'Administrateur Système chez Connit SAS, une startup basée à Toulouse spécialisée dans le système de télérelève de données, j'ai géré <strong>l'administration et le paramétrage de la supervision de la console Nagios (Centreon)</strong>, incluant deux serveurs front et deux serveurs d'analyse, le tout au sein d'OVH.

        J'ai également <strong>mis en place un domaine informatique</strong> pour Connit SAS, en intégrant le domaine déjà existant auprès d'OVH. Cela a impliqué <strong>l'installation d'un contrôleur de domaine Windows 2012 sur le site de Toulouse</strong>, ainsi qu'un autre serveur Windows hébergé chez OVH, afin d'assurer la connexion entre les deux et d'intégrer les postes de travail dans le domaine.

        Cette expérience m'a permis de renforcer mes compétences en gestion de réseaux, en supervision des infrastructures et en administration de systèmes."
      },
      {
        company: 'ITE – ALLIASERV',
        url: 'https://alliaserv.fr',
        period: '2012',
        role: 'Administrateur Système
        Juillet 2012 à Novembre 2012',
        details: "En tant qu'Administrateur Système chez Alliaserv, j'étais responsable de <strong>l'administration de serveurs dans un environnement de deux domaines (2008R2).</strong>

        J'ai également participé à <strong>la restructuration du réseau local (LAN)</strong> et à <strong>la mise en place de serveurs sous VMware</strong> pour un lycée privé.

        Cette expérience m'a permis de développer des compétences techniques en virtualisation et en gestion de réseaux, essentielles pour assurer le bon fonctionnement des infrastructures informatiques."
      },
      {
        company: 'PC30BS',
        url: 'https://solutions30.com',
        period: '2012',
        role: 'Coordinateur de projet
        Avril 2012 à Juin 2012',
        details: "En tant que Coordinateur de Projet, j'ai supervisé <strong>le déploiement de 750 postes de travail</strong> avec une équipe de <strong>3 techniciens.</strong> J'ai collaboré étroitement avec le chef de projet pour garantir la bonne exécution du projet.

        Mes responsabilités incluaient également <strong>le recrutement et la formation des techniciens sur site</strong>, ainsi que <strong>le reporting journalier</strong> pour le compte de « Les Toitures Lafarge ».

        Cette expérience m'a permis de développer mes compétences en gestion d'équipe et en coordination de projet."
      },
      {
        company: 'LINKS-CONSEIL',
        url: 'https://www.globalservices.bt.com/fr',
        period: '2009 - 2011',
        role: 'Administrateur Système
        Mars 2009 à Août 2011',
        details: "J'étais responsable de l'administration <strong>des routeurs Cisco et Huawei</strong> au sein de <strong>british télécom.</strong>

        Au sein d'une équipe de 6 personnes, nous gérions quotidiennement les incidents par région pour les entreprises, en nous concentrant sur les accès aux routeurs d'entrée.

        Si un problème était lié à <strong>un routeur, je procédais à son remplacement, incluant l'injection et la configuration</strong> de la nouvelle unité.

        En cas d’incident liés à la ligne, ceux-ci étaient renvoyés à Orange pour rétablissement. Chaque matin, nous tenions une <strong>réunion d'équipe</strong> pour faire le point sur les activités de la veille.

        De plus, j'ai participé à des projets d'amélioration, notamment en ce qui concerne <strong>l'administration à distance et la récupération des configurations</strong>, afin d'optimiser les processus avant de les réinjecter dans le changement vers un autre modèle de routeur.

        Cette expérience a renforcé mes compétences techniques et ma capacité à travailler efficacement en équipe."
      },
      {
        company: 'ATOS',
        url: 'https://atos.net/fr/qui-nous-sommes',
        period: '2008',
        role: 'Coordinateur de projet
        Août 2008 à Novembre 2008',
        details: "En tant que Coordinateur de Projet chez ATOS, j'ai fait partie d'une équipe de <strong>6 coordinateurs, sous la direction d'un manager de projet, ainsi qu'avec 3 techniciens.</strong> Nous avons coordonné le projet d'installation et de mise en service du « Passeport Biométrique ».

        Mon rôle impliquait de collaborer avec <strong>l'équipe réseau et les développeurs pour assurer la présentation et les étapes de test du projet.</strong>

        Nous étions responsables de la présentation, de la réponse aux questions et de l'assurance qualité du projet, ainsi que le <strong>reporting</strong> hebdomadaire.

        J'ai également collaboré étroitement <strong>avec le ministère, les préfets et les élus locaux</strong> pour garantir la mise en œuvre réussie du projet.

        Cette expérience m'a permis de développer mes compétences en gestion de projet et en coordination interdisciplinaire."
      }
    ]
    @experiences1_by_company = @experiences1.group_by { |exp| exp[:company] }
    @experiences2_by_company = @experiences2.group_by { |exp| exp[:company] }
    @experiences3_by_company = @experiences3.group_by { |exp| exp[:company] }

    @formations = [
      {
        title: 'Chef de projet digital',
        institution: 'DIGITAL CAMPUS PARIS',
        url: 'https://www.digital-campus.fr/glossaire-du-web/metier-chef-projet-digital?gge_source=google&gge_medium=cpc&gge_term=formation%20chef%20de%20projet%20digital&gge_campaign=Search-Metiers&gad_source=1&gclid=EAIaIQobChMI9qriufeCjAMVsD0GAB1VeCBHEAAYAiAAEgK8cvD_BwE',
        period: '2024',
        certification: 'Niveau VI - License',
        details: "La formation de Chef de Projet Digital à Digital Campus Paris vise à devenir un expert en gestion de projets digitaux.

        Elle inclut l'apprentissage de la gestion de projet, de la stratégie webmarketing et de la création de contenus digitaux.

        Les compétences acquises incluent l'analyse de la demande client, la proposition de solutions digitales et la gestion des ressources nécessaires.

        Cette formation est également transposable à un poste de Chef de Projet IT ou informatique, offrant ainsi une base solide pour gérer des projets technologiques.

        Les professionnels formés peuvent ainsi s'adapter efficacement aux exigences du secteur informatique.

        La formation, reconnue par l'État, prépare les étudiants à gérer efficacement des projets digitaux ou informatiques."
      },
      {
        title: 'MCITP',
        institution: 'Centre IFORM Toulouse-Balma',
        url: 'https://www.iform.fr',
        period: '2012',
        certification: 'Certifications Microsoft',
        details: "La formation MCITP Windows Server 2012 prépare les administrateurs système à installer, configurer et gérer Windows Server 2012.

        Elle couvre des compétences avancées telles que l'administration Active Directory, la gestion des stratégies de groupe, et l'utilisation de PowerShell.

        La certification valide des compétences essentielles pour la surveillance et la maintenance des serveurs, ainsi que la gestion du stockage et des services réseaux.

        Elle est reconnue par Microsoft et constitue une étape vers la certification MCSA et MCSE."
      },
      {
        title: 'TSSI',
        institution: 'Ifpa Ecole',
        url: 'https://www.ifpa.pro',
        period: '2006',
        certification: 'Diplome Niveau v (Bac +2)',
        details: "La formation TSSI (Technicien Supérieur Support Informatique) à l'IFPA à Mérignac te prépare à gérer les incidents informatiques, en appliquant les bonnes pratiques ITIL.

        Elle inclut le support utilisateur, le dépannage et le déploiement de postes de travail, ainsi que l'intervention sur des infrastructures réseau.

        Elle apprends à gérer le parc informatique et à suivre les configurations.  La formation développe aussi des compétences transversales, comme  l'utilisation de l'anglais professionnel et des qualités relationnelles.

        Suite à la formation TSSI, une évolution vers le poste d'administrateur système et réseau est possible, nécessitant souvent des compétences supplémentaires en systèmes d'exploitation, en virtualisation, ainsi qu'une certification comme le CCNA ou le MCSA, ou bien vers la formation Administrateur d’Infrastructures Sécurisée."
      },
      {
        title: 'Conseiller Clientèle à Distance',
        institution: 'Centre AFPA',
        url: 'https://www.afpa.fr/formation-qualifiante/conseiller-relation-client-a-distance',
        period: '2005',
        certification: 'Diplome Niveau IV (Bac)',
        details: "La formation Conseiller Service Clientèle à Distance de l'AFPA prépare à offrir un support clientèle efficace via des canaux numériques.

        Elle te forme aux techniques de communication à distance, à la gestion des outils de collaboration,  et à la résolution de problèmes clients.

        Elle forme également à gérer des situations conflictuelles et à maintenir une relation de confiance avec les clients.

        La formation permet de développer des compétences en écoute active et en  gestion du temps. Elle délivre le diplôme de Conseiller Service  Clientèle à Distance de niveau IV (Bac)."
      }
    ]

  end


  def contact
  end

  def competences
  end
end
