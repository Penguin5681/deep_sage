# Deep Sage: AI-Powered Data Analysis & Visualization Tool

A Flutter-based desktop application that serves as a one-stop solution for data scientists to search, download, analyze, and visualize datasets efficiently.

[![Flutter Build (Windows / Linux)](https://github.com/Penguin5681/deep_sage/actions/workflows/build.yml/badge.svg)](https://github.com/Penguin5681/deep_sage/actions/workflows/build.yml)

## Getting Started

Follow these steps to get Deep Sage up and running on your local machine.

### Prerequisites

- Flutter SDK (latest version recommended)
- Dart SDK
- Git
- Google Cloud Platform account (for GCP services)
- Kaggle account (for Kaggle API integration)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Penguin5681/deep_sage.git
   # OR using SSH
   git clone git@github.com:Penguin5681/deep_sage.git
   ```

2. **Navigate to the project directory**

   ```bash
   cd deep_sage
   ```

3. **Install dependencies**

   ```bash
   flutter pub get
   ```

4. **Set up environment variables**

   Create a `.env` file in the root directory of the project with the following content:

   ```dotenv
   FLUTTER_ENV=development
   SUPABASE_URL=                       # Your Supabase URL
   SUPABASE_API=                       # Your Supabase API key
   DEV_BASE_URL=http://localhost:5000  # Backend dev URL (keep as is)
   PROD_BASE_URL=                      # Production backend URL
   API_HIVE_BOX_NAME=user_api_box      # Keep as is
   RECENT_IMPORTS_HISTORY=recent_imports_history  # Keep as is
   GCP_CREDENTIALS_PATH=               # Path to your GCP service key
   GCP_PROJECT_ID=                     # Your GCP project ID
   GCP_CLOUD_BUCKET_NAME=              # Your GCP cloud bucket name
   USER_HIVE_BOX=user_box              # Keep as is
   CHART_STATE_BOX=chart_state         # Keep as is
   ```

   > **Important**: Keep all the box names as they appear above.

5. **Set up Google Cloud credentials**

  - Obtain a GCP service account key and rename it to `deepsage-service-key.json`
  - Place it in the `assets` directory so the final path is `assets/deepsage-service-key.json`

6. **Set up Google OAuth credentials**

  - Create a `client_secret.json` file for Google authentication using OAuth2
  - Place it in the `assets` directory so the final path is `assets/client_secret.json`

### Environment Variables Explained

- `FLUTTER_ENV`: Set to "development" for development mode or "production" for production
- `SUPABASE_URL` & `SUPABASE_API`: Credentials for Supabase database
- `DEV_BASE_URL`: URL for the local backend server
- `PROD_BASE_URL`: URL for the production backend server
- `API_HIVE_BOX_NAME`: Storage box for API credentials
- `RECENT_IMPORTS_HISTORY`: Storage box for recent dataset imports
- `GCP_CREDENTIALS_PATH`: Path to your Google Cloud service account key
- `GCP_PROJECT_ID`: Your Google Cloud project ID
- `GCP_CLOUD_BUCKET_NAME`: Your Google Cloud Storage bucket name
- `USER_HIVE_BOX`: Storage box for user data
- `CHART_STATE_BOX`: Storage box for chart configurations

### Setting Up the Backend

Deep Sage requires a backend service to function properly. You can find the backend repository at:

```
https://github.com/Penguin5681/Deep-Sage-Backend
```

Please follow the instructions in the backend repository to set it up correctly.

### Running the Application

After completing all the setup steps, you can run the application:

```bash
flutter run -d windows  # For Windows
# OR
flutter run -d linux    # For Linux
```

## Features

- Public Dataset Search & Download (Kaggle, Google Dataset Search, UCI, etc.)
- Data Exploration & Cleaning
- AI-Powered Data Insights
- Interactive Data Visualization
- Statistical & Machine Learning Tools
- Code & Notebook Integration
- Dataset Storage & Cloud Sync
- Report Generation

## Support

For any issues or questions, please open an issue on the GitHub repository.

## Note: This software is still under development and there may be bugs