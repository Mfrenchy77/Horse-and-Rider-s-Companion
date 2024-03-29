/// A class that returns a list of horse breeds

// ignore_for_file: lines_longer_than_80_chars

class HorseDetails {
  static List<String> breeds = [
    'Abaga',
    'Abyssinian',
    'Adaev',
    'Aegidienberger',
    'Akhal-Teke',
    'Albanian',
    'Altai',
    'Alter Real',
    'American Bashkir Curly',
    'American Belgian Draft',
    'American Cream Draft',
    'American Indian Horse',
    'American Paint Horse',
    'American Quarter Horse',
    'American Saddlebred',
    'American Warmblood',
    'Andalusian',
    'Andravida',
    'Anglo-Arabian',
    'Anglo-Kabarda',
    'Appaloosa',
    'Arabian',
    'Ardennais',
    'Arenberg-Nordkirchen',
    'Asturcón',
    'Australian Draught',
    'Australian Stock Horse',
    'Austrian Warmblood',
    'Auvergne',
    'Auxois',
    'Axios',
    'Azerbaijan',
    'Azteca',
    'Baise horse',
    'Bale',
    'Balearic horse',
    'Balikun horse',
    'Baluchi horse',
    'Banker horse',
    'Barb horse',
    'Bardigiano',
    'Bashkir horse',
    'Basque Mountain Horse',
    'Bavarian Warmblood',
    'Belgian Draught',
    'Belgian Sport Horse',
    'Belgian Trotter',
    'Belgian Warmblood',
    'Bhutia Horse',
    'Black Forest Horse',
    'Blazer horse',
    'Boerperd',
    'Borana',
    'Bosnian Mountain Horse',
    'Boulonnais horse',
    'Brandenburger',
    'Brazilian Sport Horse',
    'Breton horse',
    'British Warmblood',
    'Brumby',
    'Budyonny horse',
    'Burguete horse',
    'Burmese Horse',
    'Byelorussian Harness Horse',
    'Calabrese horse',
    'Camargue horse',
    'Camarillo White Horse',
    'Campeiro',
    'Campolina',
    'Canadian horse',
    'Canadian Pacer',
    'Carolina Marsh Tacky',
    'Carthusian Spanish horse',
    'Caspian horse',
    'Castillonnais',
    'Catria horse',
    'Cavallo Romano della Maremma Laziale',
    'Cerbat Mustang',
    'Chaidamu horse',
    'Chernomor horse',
    'Chilean horse',
    'Chinese Mongolian horse',
    'Choctaw horse',
    'Cleveland Bay',
    'Clydesdale horse',
    'Colorado Ranger',
    'Coldblood trotter',
    'Comtois horse',
    'Corsican horse',
    'Costa Rican Saddle Horse',
    'Criollo horse',
    'Croatian Coldblood',
    'Cuban Criollo',
    'Cumberland Island horse',
    'Czech Warmblood',
    'Danish Warmblood',
    'Danube Delta horse',
    'Datong horse',
    'Dole Gudbrandsdal',
    'Dongola horse',
    'Dutch Harness Horse',
    'Dutch Heavy Draft',
    'Dutch Warmblood',
    'East Bulgarian',
    'Estonian Draft',
    'Estonian Native',
    'Ethiopian horses',
    'Falabella',
    'Finnhorse',
    'Flemish Horse',
    'Fleuve',
    'Fjord horse',
    'Florida Cracker Horse',
    'Foutanké',
    'Frederiksborger',
    'Freiberger',
    'French Trotter',
    'Friesian',
    'Furioso-North Star',
    'Galiceno',
    'Galician Pony',
    'Gelderland horse',
    'Giara Horse',
    'Gidran',
    'Groningen Horse',
    'Hackney horse',
    'Haflinger',
    'Hanoverian horse',
    'Heck horse',
    'Heihe horse',
    'Henson horse',
    'Hequ horse',
    'Hirzai',
    'Hispano-Bretón',
    'Hispano-Árabe',
    'Holsteiner',
    'Horro',
    'Hungarian Warmblood',
    'Icelandic horse',
    'Indian Country-bred',
    'Iomud',
    'Irish Draught',
    'Irish Sport Horse',
    'Italian Heavy Draft',
    'Italian Trotter',
    'Jaca Navarra',
    'Jeju horse',
    'Jutland horse',
    'Kabarda horse',
    'Kafa',
    'Kaimanawa horses',
    'Kalmyk horse',
    'Karabair',
    'Karabakh horse',
    'Karachai horse',
    'Kathiawari horse',
    'Kazakh Horse',
    'Kentucky Mountain Saddle Horse',
    'Kiger Mustang',
    'Kinsky horse',
    'Koheilan',
    'Konik',
    'Kundudo',
    'Kustanair',
    'Latvian horse',
    'Lijiang pony',
    'Lipizzan',
    'Lithuanian Heavy Draught',
    'Lokai',
    'Losino horse',
    'Lundy Pony',
    'Lusitano',
    'Malopolski',
    'Mallorquín',
    'Malopolski',
    'Mangalarga',
    'Mangalarga Marchador',
    'Maremmano',
    'Marismeño horse',
    'Marwari horse',
    "M'Bayar",
    'Mecklenburger',
    'Menorquín',
    'Messara horse',
    'Metis Trotter',
    'Mezőhegyes Felver',
    'Miniature horse',
    'Misaki horse',
    'Missouri Fox Trotter',
    'Monchina',
    'Mongolian horse',
    'Monterufolino',
    'Morab',
    'Morgan horse',
    'Moyle horse',
    'Murakoz horse',
    'Murgese',
    'Mustang',
    'Namib Desert Horse',
    'Nangchen horse',
    'Narym horse',
    'National Show Horse',
    'New Kirgiz',
    'Newfoundland Pony',
    'Nivernais horse',
    'Nokota horse',
    'Noma pony',
    'Nonius horse',
    'Nooitgedacht Pony',
    'Nordlandshest/Lyngshest',
    'Noriker horse',
    'Norman Cob',
    'North Swedish Horse',
    'Norwegian Fjord horse',
    'Ob horse',
    'Oldenburg horse',
    'Orlov trotter',
    'Ostfriesen/Alt-Oldenburger',
    'Pampa horse',
    'Paso Fino',
    'Percheron',
    'Persano horse',
    'Peruvian Paso',
    'Pindos Pony',
    'Pinia',
    'Pintabian',
    'Pinto horse',
    'Pleven horse',
    'Poitevin horse',
    'Posavac horse',
    'Pottok',
    'Przewalski horse',
    'Pryor Mountain Mustang',
    'Purosangue Orientale',
    'Qatgani',
    'Quarab',
    'Quarter pony',
    'Quarter Horse',
    'Racking Horse',
    'Retuerta horse',
    'Rhenish German Coldblood',
    'Rhinelander horse',
    'Riwoche horse',
    'Rocky Mountain Horse',
    'Romanian Sporthorse',
    'Rottaler',
    'Russian Don',
    'Russian Heavy Draft',
    'Russian Trotter',
    'Saddlebred',
    'Salerno horse',
    'Samolaco horse',
    'San Fratello horse',
    'Sandalwood Pony',
    'Sarcidano horse',
    'Sardinian Anglo-Arab',
    'Sardinian horse',
    'Schleswig Coldblood',
    'Sella Italiano',
    'Selle Français',
    'Selle Français Pony',
    'Senner horse',
    'Shagya Arabian',
    'Shan horse',
    'Shetland pony',
    'Shire horse',
    'Siciliano indigeno',
    'Silesian horse',
    'Sorraia',
    'Sokolsky horse',
    'Soviet Heavy Draft',
    'Spanish Barb',
    'Spanish Jennet Horse',
    'Spanish Mustang',
    'Spanish-Norman horse',
    'Spiti Pony',
    'Spotted Saddle horse',
    'Standardbred',
    'Suffolk Punch',
    'Sugarbush Draft',
    'Sumba and Sumbawa Pony',
    'Süddeutsches Kaltblut',
    'Swedish Ardennes',
    'Swedish Warmblood',
    'Swiss Warmblood',
    'Taishū horse',
    'Takhi',
    'Tawleed',
    'Tchernomor',
    'Tennessee Walking Horse',
    'Tersk horse',
    'Thoroughbred',
    'Tibetan Pony',
    'Tiger Horse',
    'Tinker horse',
    'Tolfetano',
    'Tori horse',
    'Trait Du Nord',
    'Trakehner',
    'Tsushima horse',
    'Tuigpaard',
    'Ukrainian Riding Horse',
    'Unmol Horse',
    'Uzunyayla',
    'Ventasso Horse',
    'Virginia highlander',
    'Vlaamperd',
    'Vladimir Heavy Draft',
    'Vyatka horse',
    'Waler horse',
    'Walkaloosa',
    'Warlander',
    'Welara',
    'Welsh Cob',
    'Welsh Mountain Pony',
    'Welsh Pony',
    'Welsh Pony of Cob Type',
    'West African Barb',
    'Westphalian horse',
    'Wielkopolski',
    'Württemberger',
    'Xilingol horse',
    'Yakutian horse',
    'Yili horse',
    'Yonaguni horse',
    'Zaniskari Pony',
  ];

  /// Horse colors
  static List<String> colors = [
    'Bay',
    'Black',
    'Brown',
    'Chestnut',
    'Gray',
    'White',
    'Palomino',
    'Buckskin',
    'Dun',
    'Roan',
    'Appaloosa',
    'Paint',
    'Pinto',
    'Cremello',
    'Perlino',
    'Champagne',
    'Silver Dapple',
    'Grullo',
    'Red Dun',
    'Red Roan',
    'Blue Roan',
    'Bay Roan',
    'Sorrel',
    'Liver Chestnut',
    'Flaxen Chestnut',
    'Flaxen Liver Chestnut',
    'Flaxen Bay',
    'Flaxen Black',
    'Flaxen Gray',
    'Flaxen White',
    'Flaxen Palomino',
    'Flaxen Buckskin',
    'Flaxen Dun',
    'Flaxen Roan',
    'Flaxen Appaloosa',
    'Flaxen Paint',
    'Flaxen Pinto',
    'Flaxen Cremello',
    'Flaxen Perlino',
    'Flaxen Champagne',
    'Flaxen Silver Dapple',
    'Flaxen Grullo',
    'Flaxen Red Dun',
    'Flaxen Red Roan',
    'Flaxen Blue Roan',
    'Flaxen Bay Roan',
    'Flaxen Sorrel',
    'Flaxen Liver Chestnut',
  ];

  /// Horse Genders
  static List<String> genders = [
    'Mare',
    'Gelding',
    'Stallion',
  ];
}
