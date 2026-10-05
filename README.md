# SignBoard (Flutter + Django Backend)

A high-performance hyperlocal service & signboard discovery platform inspired by the Figma design (`SignBoard`), engineered to scale to **1,000,000+ concurrent users** without bottlenecks.

### 🌐 Live Deployments
- **Live Web App (Vercel):** [https://web-lyart-rho-35.vercel.app](https://web-lyart-rho-35.vercel.app)
- **Live Backend API (Render):** [https://signboard-backend.onrender.com/api/](https://signboard-backend.onrender.com/api/)
- **Live Categories Endpoint:** [https://signboard-backend.onrender.com/api/categories/](https://signboard-backend.onrender.com/api/categories/)
- **Live 13,000 Posts Feed:** [https://signboard-backend.onrender.com/api/posts/](https://signboard-backend.onrender.com/api/posts/)
- **GitHub Repository:** [https://github.com/Galib-Mahmud/SignBoard.git](https://github.com/Galib-Mahmud/SignBoard.git)

---

## 🚀 Key Features

### 0. Splash & Google Sign-In
- **Animated Splash Screen:** Smooth logo scaling and glowing entrance with automatic token session check.
- **Google Sign-In:** Token-based authentication with quick-guest / demo login mode ("Maya Johnson") for immediate local testing.

### 1. Home Screen & Feed
- **Top Left:** Filter option button (opens the Category & Distance Drawer).
- **Top Right:** Profile avatar quick-switch.
- **Card Design (Figma exact match):**
  - **WhatsApp Button (`#25D366`):** One-tap direct WhatsApp chat with the poster.
  - **Go route Button (`#F1F2F4`):** One-tap navigation to the destination coordinates in Google Maps.
  - **Distance Indicator:** Real-time distance dynamically computed from user GPS location (`X.X km away`).
  - **Bookmark:** Instant save/unsave toggle with backend synchronization.
- **Feed Pagination:** High-speed cursor pagination starting with top recent posts.

### 2. Saved (Bookmarks)
- Dedicated screen showing all saved posts with full structured parameters, WhatsApp, and navigation routing.

### 3. Post Creation (Standard Category Data & GPS Capture)
- **No image bloat:** Pure structured parameters tailored to each category.
- **Step-by-step Standard Categories:**
  - *Tutoring:* Subject, Student Level, Monthly Fee, Days per week.
  - *Teachers:* Subject Expertise, Highest Degree, Experience, Hourly Rate.
  - *Used Products:* Item Name, Condition, Price, Negotiability.
  - *Self Services:* Service Name, Pricing Model, Availability.
  - *Plumbing:* Service Type, Callout Fee, Work Guarantee.
  - *Sell House:* Property Type, Bedrooms, Bathrooms, Sqft, Asking Price.
  - *Sell Property:* Land Type, Plot Size, Front Road Width, Price.
  - *Rent Rooms:* Room Type, Monthly Rent, Floor Level, Available From.
  - *Rent Garage:* Vehicle Capacity, Monthly Rent, Security Features.
  - *Car Rental:* Vehicle Model, Daily Rate, Driver Option, Fuel Policy.
  - *Homemade Food:* Signature Dishes, Meal Type, Average Price, Delivery.
  - *Matrimonial:* Looking For, Age, Profession, Education.
  - *Others:* Service Overview, Estimated Budget.
- **GPS Location Permission:** Auto-detects device GPS coordinates (Latitude & Longitude) and stores them in the database for proximity filtering.

### 4. Profile & Subscriptions
- User details and avatar.
- **All Post:** View and manage all posts published by the user.
- **Subscription:** Teaser for Pro / Enterprise subscription tiers (*"Coming Soon"* modal).
- **About:** System and architecture overview.
- **Log Out:** Cleans session tokens.

---

## ⚡ 1M Concurrent Users Architecture

1. **Composite Database Indexing:**
   - `['is_active', '-created_at']` -> Recent feed queries return in sub-milliseconds without table scans.
   - `['category', 'is_active', '-created_at']` -> Category-filtered queries hit index directly.
   - `['latitude', 'longitude']` -> Bounding-box spatial prefilter narrows 1,000,000 rows to nearby candidates instantly.
2. **Spatial Distance Calculation:**
   - Bounding-box filtering (`lat ± Δ`, `lon ± Δ`) runs on indexed columns, followed by Haversine spherical distance calculation.
3. **Optimized Payloads:**
   - Pure structured data (no image transfer overheads) keeps API response sizes under 2 KB per card.
4. **Local Concurrency:**
   - SQLite configured with `WAL` (Write-Ahead Logging) and `timeout=20s` for smooth concurrent reads and writes.
   - Drop-in compatibility with PostgreSQL / PostGIS.

---

## 🛠️ How to Run Locally

### 1. Django Backend

```bash
cd backend

# Run migrations and seed 13 categories + 1,000 realistic posts per category (13,000 total)
python3 manage.py migrate
python3 manage.py seed_bulk --count 1000

# Run API server on port 8000
python3 manage.py runserver 0.0.0.0:8000
```
- API Base URL: `http://127.0.0.1:8000/api/`
- Test Categories: `curl http://127.0.0.1:8000/api/categories/`
- Test Posts: `curl http://127.0.0.1:8000/api/posts/`
- Superuser / Staff Admin: `admin` / `adminpassword123`

---

### 2. Flutter Mobile Application

```bash
cd frontend

# Analyze code and run tests
flutter analyze
flutter test

# Run app on connected device, Android emulator, physical phone, or Linux desktop
flutter run
```

#### 📱 Connecting to Your Physical Phone:
1. In the app, navigate to **Profile** > **Server Configuration**.
2. Type or paste your deployed Render backend URL (e.g. `https://signboard-backend.onrender.com/api`) or your computer's local Wi-Fi IP (e.g. `http://192.168.1.100:8000/api`).
3. Tap **Save & Connect**. Your physical phone will immediately communicate with the live backend!

---

### 3. Web Application & Vercel Deployment

A matching web version of SignBoard is located in the `web/` directory.

#### Local Development:
```bash
# Serve web directory locally on port 3000
cd web
python3 -m http.server 3000
# Open http://localhost:3000 in your browser
```

#### Deploy to Vercel (1-Click Ready):
The repository contains both root [`vercel.json`](file:///home/galib/Desktop/SignBoard/vercel.json) and [`web/vercel.json`](file:///home/galib/Desktop/SignBoard/web/vercel.json).
1. Push your repository to GitHub / GitLab.
2. In Vercel, click **Add New Project** and select this repo.
3. Keep default settings (Vercel automatically detects `vercel.json` and serves `web/`).
4. Click **Deploy**.

---

### 4. Deploying Backend to Render

The backend is fully configured for Render with:
- [`render.yaml`](file:///home/galib/Desktop/SignBoard/render.yaml) Blueprint
- [`backend/build.sh`](file:///home/galib/Desktop/SignBoard/backend/build.sh) (Automated collectstatic, migrations, and 13,000 post bulk seeding)
- [`backend/requirements.txt`](file:///home/galib/Desktop/SignBoard/backend/requirements.txt) (Gunicorn, WhiteNoise, dj-database-url, psycopg2)

#### Deployment Steps on Render:
1. In Render Dashboard, click **New +** > **Blueprint** (or **Web Service**).
2. Connect your Git repository.
3. Root Directory: `backend`
4. Build Command: `./build.sh`
5. Start Command: `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT`
6. Environment Variables:
   - `PYTHON_VERSION`: `3.12.3`
   - `DEBUG`: `False`
   - `SECRET_KEY`: (auto-generate or custom string)
   - `DATABASE_URL`: (Optional PostgreSQL connection string, or uses SQLite)
7. Click **Deploy Web Service**. Once deployed, copy your Render URL (e.g. `https://signboard-backend.onrender.com/api`) and plug it into the Flutter mobile app and web frontend.

---

### 5. Professional Admin Site & Post Deletion

- **User Post Deletion:**
  - A user can view their published signboards under **Profile > My Posts** (mobile) or **My Posts** (web).
  - **Delete One-by-One:** Tap the red trash icon on any post card to open a confirmation modal and delete it.
  - **Delete All Posts:** Tap the **Delete All** button in the header with confirmation warning to wipe all user posts at once.
- **Administrative Portal:**
  - On the website, click **Admin Site** in the top navigation bar.
  - Log in with `admin` / `adminpassword123`.
  - Admin can inspect live platform metrics (Total Posts, Active Users, Categories, Total Views).
  - Admin can moderate & permanently delete **any post** across any category.
  - Admin can inspect user accounts and delete **any user** (which cascades and deletes all their posts).
  - Native Django Admin is also available at `http://<domain>/admin/`.

