//This will have to be moved across into a hosted database
// perhap a use for ai can be found here?


class LocalHalalDatabase {
  static const Map<String, String> haramIngredients = {
    'pork': 'Pork is explicitly forbidden in Islam',
    'bacon': 'Pork product',
    'ham': 'Pork product',
    'lard': 'Pig fat',
    'pork fat': 'Pig fat',
    'pork gelatin': 'Made from pork',
    'pancetta': 'Italian bacon (pork)',
    'prosciutto': 'Italian ham (pork)',
    'chorizo': 'Often contains pork',
    'pepperoni': 'Usually contains pork',
    'salami': 'Often contains pork',

    // Alcohol
    'alcohol': 'Intoxicant forbidden in Islam',
    'ethanol': 'Alcohol',
    'ethyl alcohol': 'Alcohol',
    'wine': 'Alcoholic beverage',
    'beer': 'Alcoholic beverage',
    'rum': 'Alcoholic beverage',
    'vodka': 'Alcoholic beverage',
    'whiskey': 'Alcoholic beverage',
    'brandy': 'Alcoholic beverage',
    'sake': 'Rice wine (alcoholic)',
    'champagne': 'Alcoholic beverage',
    'mirin': 'Japanese cooking wine',
    'cooking wine': 'Contains alcohol',
    'vanilla extract': 'Usually contains alcohol',
    'rum extract': 'Contains alcohol',

    // Animal-based (uncertain slaughter)
    'gelatin': 'Often from pork or non-halal animals',
    'rennet': 'Often from non-halal animals',
    'whey': 'May contain non-halal rennet',
    'pepsin': 'Enzyme from pig stomach',
    'lipase': 'May be from non-halal animals',
    'animal shortening': 'Unknown animal source',
    'beef extract': 'Uncertain if halal slaughtered',
    'chicken extract': 'Uncertain if halal slaughtered',
    'stock': 'May contain non-halal animal products',
    'broth': 'May contain non-halal animal products',

    'e120': 'Carmine - made from insects',
    'e441': 'Gelatin - often from pork',
    'e542': 'Bone phosphate - from animal bones',
    'e904': 'Shellac - from insects',
  };

  static const Map<String, String> questionableIngredients = {
    'mono and diglycerides': 'Can be from plant or animal fat',
    'glycerin': 'Can be from plant or animal sources',
    'glycerol': 'Can be from plant or animal sources',
    'lecithin': 'Usually from soy, but can be from eggs',
    'emulsifier': 'Source not specified',
    'natural flavors': 'Source not specified, may contain alcohol',
    'artificial flavors': 'May contain alcohol as carrier',
    'enzymes': 'Source not specified',
    'l-cysteine': 'Can be from hair (often human or pig)',
    'stearic acid': 'Can be from animal or plant sources',
    'magnesium stearate': 'Can be from animal or plant sources',
    'calcium stearate': 'Can be from animal or plant sources',
    'vitamin d3': 'Often from sheep wool',
    'omega-3': 'Check if from fish or other sources',

    'e120': 'Cochineal - made from insects',
    'e322': 'Lecithin - check source',
    'e422': 'Glycerol - check source',
    'e470': 'Fatty acid salts - check source',
    'e471': 'Mono and diglycerides - check source',
    'e472': 'Esters of fatty acids - check source',
    'e473': 'Sucrose esters - check source',
    'e474': 'Sucroglycerides - check source',
    'e475': 'Polyglycerol esters - check source',
    'e476': 'Polyglycerol polyricinoleate - check source',
    'e477': 'Propane-1,2-diol esters - check source',
    'e481': 'Sodium stearoyl lactylate - check source',
    'e482': 'Calcium stearoyl lactylate - check source',
    'e483': 'Stearyl tartrate - check source',
    'e491': 'Sorbitan monostearate - check source',
    'e492': 'Sorbitan tristearate - check source',
    'e493': 'Sorbitan monolaurate - check source',
    'e494': 'Sorbitan monooleate - check source',
    'e495': 'Sorbitan monopalmitate - check source',
  };

  static const List<String> halalCertifications = [
    'halal certified',
    'halal',
    'halal certification',
    'islamic food council',
    'ifanca',
    'iswa halal',
    'halal monitoring',
    'halal authority',
    'zabiha halal',
  ];

  static bool hasHalalCertification(String text) {
    final lowerText = text.toLowerCase();
    return halalCertifications.any((cert) => lowerText.contains(cert));
  }

  // Check ingredients in text
  static Map<String, List<String>> analyzeText(String text) {
    final lowerText = text.toLowerCase();

    List<String> foundHaram = [];
    List<String> foundQuestionable = [];
    List<String> reasons = [];

    // Check for haram ingredients
    haramIngredients.forEach((ingredient, reason) {
      if (lowerText.contains(ingredient)) {
        foundHaram.add(ingredient);
        reasons.add(reason);
      }
    });

    // Check for questionable ingredients
    questionableIngredients.forEach((ingredient, reason) {
      if (lowerText.contains(ingredient)) {
        foundQuestionable.add(ingredient);
        reasons.add(reason);
      }
    });

    return {
      'haram': foundHaram,
      'questionable': foundQuestionable,
      'reasons': reasons,
    };
  }
}