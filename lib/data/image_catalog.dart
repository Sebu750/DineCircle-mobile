/// Asset paths for the bundled photography.
///
/// Extracted from the old mock-data file so the create-wizard image picker
/// (and any other offline surface) can still reference the bundled shots.
abstract final class Img {
  static const dinner = 'assets/images/dinners';
  static const venue = 'assets/images/restaurants';
  static const people = 'assets/images/people';

  static const longTable = '$dinner/long_table.jpg';
  static const omakase = '$dinner/omakase.jpg';
  static const rooftop = '$dinner/rooftop.jpg';
  static const trattoria = '$dinner/trattoria.jpg';
  static const wineTasting = '$dinner/wine_tasting.jpg';
  static const fireFeast = '$dinner/fire_feast.jpg';
  static const dessertTasting = '$dinner/dessert_tasting.jpg';
  static const supperClub = '$dinner/supper_club.jpg';

  static const izakaya = '$venue/izakaya.jpg';
  static const bistro = '$venue/bistro.jpg';
  static const gardenTerrace = '$venue/garden_terrace.jpg';
  static const wineCellar = '$venue/wine_cellar.jpg';
  static const farmKitchen = '$venue/farm_kitchen.jpg';

  static const nora = '$people/nora.jpg';
  static const ava = '$people/ava.jpg';
  static const marco = '$people/marco.jpg';
  static const yuki = '$people/yuki.jpg';

  /// Every dinner photo, used by the create-wizard image picker.
  static const List<String> dinnerGallery = [
    longTable,
    omakase,
    rooftop,
    trattoria,
    wineTasting,
    fireFeast,
    dessertTasting,
    supperClub,
  ];

  /// Every venue photo.
  static const List<String> venueGallery = [
    izakaya,
    bistro,
    gardenTerrace,
    wineCellar,
    farmKitchen,
  ];

  /// Every portrait.
  static const List<String> peopleGallery = [nora, ava, marco, yuki];
}
