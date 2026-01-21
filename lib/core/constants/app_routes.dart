class AppRoutes {
  AppRoutes._();

  // Screens
 // static const String splash = '/splash';

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String vehicleDetail = '/vehicle-detail';
  static const String addVehicle = '/add-vehicle';
  static const String editVehicle = '/edit-vehicle';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String favorites = '/favorites';
  static const String chatList = '/chat-list';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String search = '/search';


  static Map<String, String> get routeNames => {
        //splash: 'Splash',
        login: 'Connexion',
        register: 'Inscription',
        home: 'Accueil',
        vehicleDetail: 'Détails véhicule',
        addVehicle: 'Ajouter véhicule',
        editVehicle: 'Modifier véhicule',
        profile: 'Profil',
        favorites: 'Favoris',
        chatList: 'Messages',
        chat: 'Discussion',
        settings: 'Paramètres',
      };
}