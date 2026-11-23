import '../models/pantry_item.dart';

class SeedData {
  /// 1. Starter Pantry Items (automatically loaded if user's pantry is empty)
  static List<PantryItem> starterPantryItems() {
    final now = DateTime.now();
    return [
      PantryItem(
        id: 'seed-1',
        name: 'Eggs',
        category: FoodCategory.protein,
        quantity: 6,
        unit: 'pcs',
        expiryDate: now.add(const Duration(days: 2)), // Triggers "Use First!"
        storageLocation: StorageLocation.fridge,
      ),
      PantryItem(
        id: 'seed-2',
        name: 'Milk',
        category: FoodCategory.dairy,
        quantity: 1,
        unit: 'L',
        expiryDate: now.add(const Duration(days: 3)),
        storageLocation: StorageLocation.fridge,
      ),
      PantryItem(
        id: 'seed-3',
        name: 'Tomato',
        category: FoodCategory.vegetables,
        quantity: 3,
        unit: 'pcs',
        expiryDate: now.add(const Duration(days: 5)),
        storageLocation: StorageLocation.fridge,
      ),
      PantryItem(
        id: 'seed-4',
        name: 'Carrots',
        category: FoodCategory.vegetables,
        quantity: 2,
        unit: 'pcs',
        expiryDate: now.add(const Duration(days: 7)),
        storageLocation: StorageLocation.fridge,
      ),
      PantryItem(
        id: 'seed-5',
        name: 'Chicken Breast',
        category: FoodCategory.protein,
        quantity: 500,
        unit: 'g',
        expiryDate: now.add(const Duration(days: 60)),
        storageLocation: StorageLocation.freezer,
      ),
      PantryItem(
        id: 'seed-6',
        name: 'Rice',
        category: FoodCategory.grains,
        quantity: 1,
        unit: 'kg',
        expiryDate: now.add(const Duration(days: 180)),
        storageLocation: StorageLocation.shelf,
      ),
    ];
  }

  /// 2. 50 Common Dorm Food Items (Catalog + Autocomplete + Default Shelf Life)
  static const List commonDormFoods = [
    {'name': 'Eggs', 'category': 'protein', 'days': 14, 'unit': 'pcs'},
    {'name': 'Rice', 'category': 'grains', 'days': 180, 'unit': 'kg'},
    {'name': 'Milk', 'category': 'dairy', 'days': 7, 'unit': 'L'},
    {'name': 'Tomato', 'category': 'vegetables', 'days': 5, 'unit': 'pcs'},
    {'name': 'Carrots', 'category': 'vegetables', 'days': 10, 'unit': 'pcs'},
    {'name': 'Chicken Breast', 'category': 'protein', 'days': 3, 'unit': 'g'},
    {'name': 'Canned Tuna', 'category': 'protein', 'days': 365, 'unit': 'pcs'},
    {'name': 'Sardines in Tomato Sauce', 'category': 'protein', 'days': 365, 'unit': 'pcs'},
    {'name': 'Corned Beef', 'category': 'protein', 'days': 365, 'unit': 'pcs'},
    {'name': 'Instant Ramen', 'category': 'grains', 'days': 180, 'unit': 'pcs'},
    {'name': 'Pancit Canton', 'category': 'grains', 'days': 180, 'unit': 'pcs'},
    {'name': 'Bread Loaf', 'category': 'grains', 'days': 5, 'unit': 'pcs'},
    {'name': 'Oats', 'category': 'grains', 'days': 180, 'unit': 'g'},
    {'name': 'Pasta', 'category': 'grains', 'days': 365, 'unit': 'g'},
    {'name': 'Egg Noodles', 'category': 'grains', 'days': 90, 'unit': 'g'},
    {'name': 'Garlic', 'category': 'vegetables', 'days': 21, 'unit': 'pcs'},
    {'name': 'Onion', 'category': 'vegetables', 'days': 21, 'unit': 'pcs'},
    {'name': 'Potato', 'category': 'vegetables', 'days': 14, 'unit': 'pcs'},
    {'name': 'Cabbage', 'category': 'vegetables', 'days': 7, 'unit': 'pcs'},
    {'name': 'Kangkong', 'category': 'vegetables', 'days': 3, 'unit': 'g'},
    {'name': 'Pechay', 'category': 'vegetables', 'days': 4, 'unit': 'g'},
    {'name': 'Eggplant', 'category': 'vegetables', 'days': 5, 'unit': 'pcs'},
    {'name': 'String Beans', 'category': 'vegetables', 'days': 5, 'unit': 'g'},
    {'name': 'Bell Pepper', 'category': 'vegetables', 'days': 7, 'unit': 'pcs'},
    {'name': 'Cucumber', 'category': 'vegetables', 'days': 7, 'unit': 'pcs'},
    {'name': 'Banana', 'category': 'vegetables', 'days': 5, 'unit': 'pcs'},
    {'name': 'Calamansi', 'category': 'vegetables', 'days': 7, 'unit': 'pcs'},
    {'name': 'Hotdog', 'category': 'protein', 'days': 14, 'unit': 'pcs'},
    {'name': 'Tocino', 'category': 'protein', 'days': 14, 'unit': 'g'},
    {'name': 'Longganisa', 'category': 'protein', 'days': 14, 'unit': 'pcs'},
    {'name': 'Spam / Luncheon Meat', 'category': 'protein', 'days': 365, 'unit': 'pcs'},
    {'name': 'Tofu', 'category': 'protein', 'days': 5, 'unit': 'pcs'},
    {'name': 'Egg Tofu', 'category': 'protein', 'days': 7, 'unit': 'pcs'},
    {'name': 'Ground Pork', 'category': 'protein', 'days': 2, 'unit': 'g'},
    {'name': 'Cheese Slices', 'category': 'dairy', 'days': 21, 'unit': 'pcs'},
    {'name': 'Butter', 'category': 'dairy', 'days': 30, 'unit': 'g'},
    {'name': 'Yogurt', 'category': 'dairy', 'days': 10, 'unit': 'pcs'},
    {'name': 'Condensed Milk', 'category': 'dairy', 'days': 180, 'unit': 'pcs'},
    {'name': 'Soy Sauce', 'category': 'other', 'days': 365, 'unit': 'L'},
    {'name': 'Vinegar', 'category': 'other', 'days': 365, 'unit': 'L'},
    {'name': 'Cooking Oil', 'category': 'other', 'days': 180, 'unit': 'L'},
    {'name': 'Oyster Sauce', 'category': 'other', 'days': 180, 'unit': 'g'},
    {'name': 'Tomato Sauce', 'category': 'other', 'days': 180, 'unit': 'g'},
    {'name': 'Ketchup', 'category': 'other', 'days': 180, 'unit': 'g'},
    {'name': 'Mayonnaise', 'category': 'other', 'days': 90, 'unit': 'g'},
    {'name': 'Peanut Butter', 'category': 'other', 'days': 180, 'unit': 'g'},
    {'name': 'Miso Paste', 'category': 'other', 'days': 180, 'unit': 'g'},
    {'name': 'Nori Seaweed', 'category': 'other', 'days': 180, 'unit': 'pcs'},
    {'name': 'Tortilla Wraps', 'category': 'grains', 'days': 14, 'unit': 'pcs'},
    {'name': 'Crackers', 'category': 'grains', 'days': 90, 'unit': 'pcs'},
  ];

  /// 3. 30 Dorm-Friendly Recipes (Tagged by required dorm equipment)
  static const List seededRecipes = [
    {
      'title': 'Creamy Egg Fried Rice',
      'prep_minutes': 15,
      'equipment': ['Rice Cooker', 'Electric Pan'],
      'ingredients': ['Rice', 'Eggs', 'Garlic', 'Soy Sauce', 'Cooking Oil'],
      'steps': [
        'Cook rice in the rice cooker or use leftover cold rice.',
        'Beat 2 eggs with a splash of soy sauce.',
        'Sauté minced garlic in oil, scramble the eggs softly, and toss in the rice for 3 minutes.',
      ],
    },
    {
      'title': 'One-Pot Rice Cooker Chicken Adobo',
      'prep_minutes': 25,
      'equipment': ['Rice Cooker'],
      'ingredients': ['Chicken Breast', 'Soy Sauce', 'Vinegar', 'Garlic'],
      'steps': [
        'Place chicken, 3 tbsp soy sauce, 2 tbsp vinegar, crushed garlic, and 1/4 cup water in the rice cooker.',
        'Press Cook and simmer for 20 minutes until chicken is tender and sauce reduces.',
      ],
    },
    {
      'title': 'Microwave Mug Omelette',
      'prep_minutes': 5,
      'equipment': ['Microwave'],
      'ingredients': ['Eggs', 'Tomato', 'Cheese Slices', 'Milk'],
      'steps': [
        'Whisk 2 eggs with 1 tbsp milk in a microwave-safe mug.',
        'Stir in diced tomato and torn cheese.',
        'Microwave on high for 90 seconds until fluffy.',
      ],
    },
    {
      'title': 'Kettle Egg Drop Ramen',
      'prep_minutes': 7,
      'equipment': ['Kettle'],
      'ingredients': ['Instant Ramen', 'Eggs', 'Kangkong'],
      'steps': [
        'Boil water in the electric kettle.',
        'Pour boiling water over ramen noodles and seasoning in a covered bowl for 3 minutes.',
        'Crack an egg into the hot broth, stir gently, and top with kangkong leaves.',
      ],
    },
    {
      'title': 'Garlic Butter Tuna Pasta',
      'prep_minutes': 15,
      'equipment': ['Hot Plate', 'Electric Pan'],
      'ingredients': ['Pasta', 'Canned Tuna', 'Garlic', 'Butter'],
      'steps': [
        'Boil pasta on the hot plate until al dente, then drain.',
        'Melt butter, sauté garlic, and toss in drained canned tuna and pasta.',
      ],
    },
    {
      'title': 'Sardines & Egg Rice Bowl',
      'prep_minutes': 10,
      'equipment': ['Rice Cooker', 'Hot Plate'],
      'ingredients': ['Sardines in Tomato Sauce', 'Eggs', 'Rice', 'Onion'],
      'steps': [
        'Sauté sliced onion, pour in canned sardines, and simmer for 3 minutes.',
        'Crack an egg on top, cover until set, and serve over warm rice.',
      ],
    },
    {
      'title': 'Cheesy Tuna Melt Toast',
      'prep_minutes': 8,
      'equipment': ['Toaster', 'Microwave'],
      'ingredients': ['Bread Loaf', 'Canned Tuna', 'Mayonnaise', 'Cheese Slices'],
      'steps': [
        'Toast two slices of bread.',
        'Mix drained tuna with mayonnaise, spread on toast, top with cheese, and microwave 20 seconds to melt.',
      ],
    },
    {
      'title': 'Rice Cooker Hainanese Chicken Rice',
      'prep_minutes': 30,
      'equipment': ['Rice Cooker'],
      'ingredients': ['Rice', 'Chicken Breast', 'Garlic', 'Soy Sauce'],
      'steps': [
        'Add washed rice, water, crushed garlic, and chicken breast into the rice cooker.',
        'Press Cook. Once done, slice chicken and drizzle with soy sauce.',
      ],
    },
    {
      'title': 'Hot Plate Corned Beef Hash',
      'prep_minutes': 12,
      'equipment': ['Hot Plate', 'Electric Pan'],
      'ingredients': ['Corned Beef', 'Potato', 'Onion', 'Garlic'],
      'steps': [
        'Dice potato into small cubes and pan-fry until golden.',
        'Add onion, garlic, and corned beef; cook until slightly crispy.',
      ],
    },
    {
      'title': 'Kettle Creamy Oatmeal & Banana',
      'prep_minutes': 5,
      'equipment': ['Kettle'],
      'ingredients': ['Oats', 'Milk', 'Banana', 'Peanut Butter'],
      'steps': [
        'Pour boiling water from the kettle over oats and let sit 3 minutes.',
        'Stir in milk, sliced banana, and a spoonful of peanut butter.',
      ],
    },
    {
      'title': 'Microwave Steamed Egg Custard',
      'prep_minutes': 6,
      'equipment': ['Microwave'],
      'ingredients': ['Eggs', 'Soy Sauce', 'Cooking Oil'],
      'steps': [
        'Whisk 2 eggs with 1/2 cup warm water.',
        'Cover bowl with a plate and microwave on medium for 4 minutes; drizzle with soy sauce.',
      ],
    },
    {
      'title': 'Spam & Egg Musubi Bowl',
      'prep_minutes': 12,
      'equipment': ['Electric Pan', 'Rice Cooker'],
      'ingredients': ['Spam / Luncheon Meat', 'Eggs', 'Rice', 'Soy Sauce', 'Nori Seaweed'],
      'steps': [
        'Pan-fry sliced Spam and scrambled eggs.',
        'Serve over rice with a splash of soy sauce and crumbled nori.',
      ],
    },
    {
      'title': 'Tofu & Kangkong Oyster Stir-Fry',
      'prep_minutes': 12,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['Tofu', 'Kangkong', 'Oyster Sauce', 'Garlic'],
      'steps': [
        'Pan-fry cubed tofu until golden.',
        'Add garlic, kangkong, and 2 tbsp oyster sauce; toss for 2 minutes.',
      ],
    },
    {
      'title': 'Eggplant Omelette (Tortang Talong)',
      'prep_minutes': 15,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['Eggplant', 'Eggs', 'Cooking Oil'],
      'steps': [
        'Roast or pan-soften whole eggplant until tender, peel skin, and flatten with a fork.',
        'Dip in beaten egg and pan-fry both sides until golden brown.',
      ],
    },
    {
      'title': 'Rice Cooker Tomato Rice',
      'prep_minutes': 20,
      'equipment': ['Rice Cooker'],
      'ingredients': ['Rice', 'Tomato', 'Garlic', 'Soy Sauce', 'Cooking Oil'],
      'steps': [
        'Put washed rice, water, 1 tbsp soy sauce, and 1 tsp oil in the rice cooker.',
        'Place a whole cored tomato in the center and press Cook; mash tomato into rice when done.',
      ],
    },
    {
      'title': 'Microwave Loaded Baked Potato',
      'prep_minutes': 10,
      'equipment': ['Microwave'],
      'ingredients': ['Potato', 'Cheese Slices', 'Butter'],
      'steps': [
        'Pierce potato with a fork and microwave for 7–8 minutes until soft.',
        'Slice open, mash inside with butter, and top with melted cheese.',
      ],
    },
    {
      'title': 'Sweet & Savory Tocino Fried Rice',
      'prep_minutes': 15,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['Tocino', 'Rice', 'Eggs', 'Garlic'],
      'steps': [
        'Cook diced tocino in a pan until caramelized.',
        'Toss in garlic and leftover rice, and top with a fried egg.',
      ],
    },
    {
      'title': 'Pancit Canton Special',
      'prep_minutes': 8,
      'equipment': ['Kettle', 'Hot Plate'],
      'ingredients': ['Pancit Canton', 'Eggs', 'Carrots', 'Cabbage'],
      'steps': [
        'Boil noodles with julienned carrots and shredded cabbage for 3 minutes.',
        'Drain, toss with seasoning packets, and top with a boiled or fried egg.',
      ],
    },
    {
      'title': 'Microwave Cheesy Quesadilla',
      'prep_minutes': 4,
      'equipment': ['Microwave', 'Electric Pan'],
      'ingredients': ['Tortilla Wraps', 'Cheese Slices', 'Chicken Breast', 'Tomato'],
      'steps': [
        'Layer cheese, diced cooked chicken, and tomato on half a tortilla and fold.',
        'Microwave 45 seconds or toast in a dry pan until crisp.',
      ],
    },
    {
      'title': 'Hotdog & Cabbage Stir-Fry',
      'prep_minutes': 10,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['Hotdog', 'Cabbage', 'Garlic', 'Soy Sauce'],
      'steps': [
        'Slice hotdogs diagonally and pan-fry with garlic.',
        'Add shredded cabbage and 1 tbsp soy sauce; cook 3 minutes until tender-crisp.',
      ],
    },
    {
      'title': 'Kettle Miso Tofu Soup',
      'prep_minutes': 5,
      'equipment': ['Kettle'],
      'ingredients': ['Miso Paste', 'Egg Tofu', 'Nori Seaweed'],
      'steps': [
        'Dissolve 1 tbsp miso paste in a bowl of kettle-boiled water.',
        'Add cubed egg tofu and torn nori strips.',
      ],
    },
    {
      'title': 'Creamy Tomato Egg Stir-Fry',
      'prep_minutes': 10,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['Tomato', 'Eggs', 'Garlic', 'Ketchup'],
      'steps': [
        'Scramble 3 eggs softly and set aside.',
        'Sauté tomato wedges with garlic and 1 tbsp ketchup, then fold eggs back in.',
      ],
    },
    {
      'title': 'Longganisa & Garlic Rice (Longsilog)',
      'prep_minutes': 18,
      'equipment': ['Electric Pan', 'Rice Cooker'],
      'ingredients': ['Longganisa', 'Rice', 'Eggs', 'Garlic'],
      'steps': [
        'Simmer longganisa in 1/4 cup water until water evaporates and sausages brown.',
        'Serve with garlic fried rice and a sunny-side-up egg.',
      ],
    },
    {
      'title': 'Peanut Butter Banana Toast',
      'prep_minutes': 4,
      'equipment': ['Toaster'],
      'ingredients': ['Bread Loaf', 'Peanut Butter', 'Banana'],
      'steps': [
        'Toast bread slices until golden.',
        'Spread peanut butter generously and layer sliced banana on top.',
      ],
    },
    {
      'title': 'Rice Cooker Pork Giniling',
      'prep_minutes': 25,
      'equipment': ['Rice Cooker'],
      'ingredients': ['Ground Pork', 'Tomato Sauce', 'Potato', 'Carrots', 'Garlic'],
      'steps': [
        'Sauté garlic and ground pork in the rice cooker on Cook mode.',
        'Add diced potato, carrots, and tomato sauce; cook 15 minutes until tender.',
      ],
    },
    {
      'title': 'Garlic String Beans Adobo',
      'prep_minutes': 12,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['String Beans', 'Soy Sauce', 'Vinegar', 'Garlic'],
      'steps': [
        'Sauté garlic and cut string beans in oil for 3 minutes.',
        'Add 2 tbsp soy sauce and 1 tbsp vinegar; simmer until tender.',
      ],
    },
    {
      'title': 'Microwave Pizza Bread',
      'prep_minutes': 5,
      'equipment': ['Microwave', 'Toaster'],
      'ingredients': ['Bread Loaf', 'Tomato Sauce', 'Cheese Slices', 'Hotdog'],
      'steps': [
        'Spread tomato sauce on bread, top with sliced hotdog and cheese.',
        'Microwave 45 seconds until cheese bubbles.',
      ],
    },
    {
      'title': 'Crispy Tofu Sisig',
      'prep_minutes': 15,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['Tofu', 'Onion', 'Mayonnaise', 'Soy Sauce', 'Calamansi'],
      'steps': [
        'Dice tofu and fry until crispy.',
        'Toss with chopped onion, 1 tbsp mayonnaise, 1 tbsp soy sauce, and calamansi juice.',
      ],
    },
    {
      'title': 'Tuna & Cucumber Crackers Snack',
      'prep_minutes': 5,
      'equipment': ['Kettle'],
      'ingredients': ['Canned Tuna', 'Mayonnaise', 'Cucumber', 'Crackers'],
      'steps': [
        'Mix canned tuna with mayonnaise and diced cucumber.',
        'Spoon onto crackers for a no-cook dorm snack.',
      ],
    },
    {
      'title': 'Veggie Egg Noodle Stir-Fry',
      'prep_minutes': 15,
      'equipment': ['Electric Pan', 'Hot Plate'],
      'ingredients': ['Egg Noodles', 'Carrots', 'Cabbage', 'Soy Sauce', 'Oyster Sauce'],
      'steps': [
        'Boil egg noodles for 3 minutes and drain.',
        'Stir-fry carrots and cabbage, then toss in noodles with soy sauce and oyster sauce.',
      ],
    },
  ];
}