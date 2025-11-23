# Money Mirror

Money Mirror is a modern Flutter app for personal finance management. Track your accounts, transactions, budgets, and analyze your spending trends with a beautiful, intuitive interface.

## Features

- **Accounts Management:** Add and manage multiple financial accounts.
- **Transactions:** Record income and expenses, categorize transactions, and view transaction history.
- **Budgets:** Set budgets for categories and monitor your spending.
- **Categories:** Organize transactions by customizable categories.
- **Analysis & Trends:** Visualize your financial data with overview, categories, and trends tabs.
- **CSV Import:** Import transactions from CSV files for easy migration.
- **Onboarding:** Guided onboarding for new users.
- **Settings:** Personalize your app experience, including theme switching.

## App Structure

```
lib/
  main.dart                # App entry point
  app_routes.dart          # Route management
  core/                    # Core utilities and theme manager
  database/                # Database handler, DAOs, schema, seeder
  models/                  # Data models (Account, Budget, Category, Transaction)
  features/                # Feature modules (e.g., import from CSV)
  views/
	 screens/               # UI screens (Home, Accounts, Budgets, Analysis, etc.)
	 widgets/               # Reusable UI components
assets/
  images/                  # App icons and onboarding images
```

## Technologies

- **Flutter** (SDK ^3.9.2)
- **sqflite** (local database)
- **path** (file paths)
- **fluttertoast** (notifications)
- **cupertino_icons** (iOS-style icons)

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone https://github.com/RamaScript/money-mirror.git
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Run the app:**
   ```sh
   flutter run
   ```

## Screenshots

Add screenshots of your app in the `assets/images/` folder and display them here:

```
![Home Screen](assets/images/onboard/home.png)
![Analysis Screen](assets/images/onboard/analysis.png)
```

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License.
