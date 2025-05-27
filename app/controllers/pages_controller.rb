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
      { image: "Ferrat_sdsrzq", name: "Francois FERRAT", testimony: "Organisé, sens des priorités, gestion de la pression, respect de la hiérarchie, large faculté d'adaptation, certes réactif sans omettre sa proactivité, . . ."},
      { image: "alexia_k2ueok", name: "Alexia ONG", testimony: "C'est avec un grand plaisir que je recommande chaleureusement Benoît pour toute opportunité professionnelle. Durant notre collaboration chez Computacenter, Benoît a fait preuve d'un grand professionnalisme, d'une expertise technique solide et d'un engagement exemplaire durant sa mission.
      Son analyse et ses conseils techniques ont permis de trouver des solutions aux difficultés rencontrées.
      Il se distingue notamment par son fort esprit d'équipe, qui permet de réussir les objectifs fixés dans une ambiance de travail harmonieuse. Il se rend toujours disponible pour aider ses collègues. Ce qui est fort appréciable.
      Sa bonne humeur, sa fiabilité et son attitude positive font de lui un atout précieux pour toute organisation et future équipe."},
      { image: "Anne_BERTINETTI_rjzuyn", name: "Anne BERTINETTI", testimony: "Anne BERTINETTI, Chef du département Gestion des Ressources de la Direction de la Sécurité de l'Aviation Civile Sud-Ouest, atteste que Monsieur Benoît MARFANY, a rempli avec sérieux sa mission dans nos services du 1er juin 2015 au 31 mars 2016 en tant qu’administrateur Système.
      M. MARFANY, disponible, possède de bonnes qualités professionnelles et a donné entière satisfaction sur son poste."},
      { image: "Flavien_villant_lbtcon", name: "Flavien VILLANT", testimony: "Monsieur Marfany Benoit à travaillé dans notre société, ITE, du Groupe Alliaserv, en tant qu’Administrateur système et réseaux, de juin à septembre 2012.
      Dans le cadre de cette fonction, Monsieur Marfany a su, durant tout le temps qu’il a passé chez nous, faire preuve de professionnalisme et de sérieux.
      En outre, son travail s’est avéré de très bonne qualité.
      Son sens des responsabilités lui permet de s’adapter très facilement aux nouveaux environnements de travail et sa maitrise des systèmes informatiques lui permet de proposer des solutions adaptées aux besoins des utilisateurs."}
    ]
  end
  def about
  end
  def contact
  end
  def competences
  end
end
