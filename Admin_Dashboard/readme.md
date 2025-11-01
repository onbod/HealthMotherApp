# 🌸 HealthyMother — Empowering Maternal Health with Technology

---

## 👩‍⚕️ About HealthyMother

**HealthyMother** is a modern, user-friendly dashboard for maternal health management. It empowers healthcare providers and clinicians to efficiently manage patient data, send notifications, review reports, and deliver health education—all in a beautiful, responsive web app.

HealthyMother now features **full PostgreSQL database support** for persistent, real-world data management, alongside modern health data standards.

---

## ✨ Key Features

- **Role-Based Login**: Log in as App Admin or Clinician (local, no real authentication)
- **Insightful Dashboard**: View key metrics, trends, and upcoming due dates
- **Patient Management**: Browse, search, and view detailed patient records
- **Referral Tracking**: Manage and review patient referrals
- **Notifications**: Create, schedule, and manage notifications for patients
- **Health Education Hub**: Create and manage health tips, nutrition advice, and videos
- **Whistleblower Reports**: Review, filter, and respond to anonymous reports
- **PostgreSQL Database**: All patients, referrals, notifications, and reports are stored and managed in PostgreSQL
- **Database Navigation**: Access database settings, sync status, and data management tools from the sidebar
- **Modern UI**: Responsive, mobile-friendly, and visually consistent

---

## 🖼️ Screenshots

> _Add screenshots of the dashboard, patient detail, notifications, and reports pages here._

---

## 🚀 Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher recommended)
- [pnpm](https://pnpm.io/) (or npm/yarn)
- [PostgreSQL](https://www.postgresql.org/) (required)

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/SahrDauda/healthapp.git
   cd healthapp
   ```

2. **Install dependencies:**

   ```bash
   pnpm install
   # or
   npm install
   # or
   yarn install
   ```

3. **Configure your database:**

   - Ensure PostgreSQL is running locally or accessible remotely.
   - Create a database (e.g., `healthmother`).
   - Copy `.env.example` to `.env` and fill in your PostgreSQL connection details:

     ```env
     DATABASE_URL=postgresql://user:password@localhost:5432/healthmother
     ```

   - Run database migrations (if provided):

     ```bash
     pnpm db:migrate
     # or
     npm run db:migrate
     # or
     yarn db:migrate
     ```

4. **Start the development server:**

   ```bash
   pnpm dev
   # or
   npm run dev
   # or
   yarn dev
   ```

5. **Open your browser:**

   Visit [http://localhost:3000](http://localhost:3000)

   **Note**: The Admin Dashboard connects to the Railway backend at `https://health-fhir-backend-production-6ae1.up.railway.app`

---

## 🗂️ Project Structure

```
healthapp/
  app/                # Next.js app directory (routes, layouts)
  components/         # Reusable React components
  hooks/              # Custom React hooks
  lib/                # Utility libraries (database, FHIR, etc.)
  public/             # Static assets (images, logos)
  styles/             # Global styles (Tailwind CSS)
  ...
```

---

## 🧑‍💻 Usage Guide

### 1. **Login**
- Use the login page to sign in as either "App Admin" or "Clinician".
- The role is stored in your browser's localStorage.

### 2. **Navigation**
- The sidebar and navigation update based on your role.
- "App Admin" sees all features; "Clinician" sees a limited dashboard.
- **Database:** A sidebar section for "Database" lets you view sync status, manage data, and configure PostgreSQL settings.

### 3. **Dashboard**
- View key metrics, charts, and upcoming due dates.
- Dashboard metrics are powered by real data from PostgreSQL.

### 4. **Patients & Referrals**
- Browse patient and referral lists with summary cards and tables.
- Click a patient to view detailed medical records and visit history.
- All patient and referral data is stored and managed in PostgreSQL.

### 5. **Notifications**
- Create, edit, and schedule notifications for patients.
- Notifications are persisted and managed in PostgreSQL.

### 6. **Health Education**
- Manage health tips, nutrition advice, and videos.
- Create, edit, and send tips to patients.
- Health tips and education content are stored in PostgreSQL.

### 7. **Reports**
- Review, filter, and respond to anonymous whistleblower reports.
- Mark reports as read/unread and send replies.
- Reports and responses are saved in PostgreSQL for audit and compliance.

### 8. **Database Management**
- Access the "Database" section from the sidebar.
- View database connection status, sync data, and manage tables.
- Configure PostgreSQL connection settings (host, port, user, password, database name) via a UI form.
- See real-time sync indicators and error messages if the database is unavailable.

---

## 🛠️ Built With

- **Next.js 14+** (React 18)
- **TypeScript**
- **Tailwind CSS**
- **Shadcn/UI** & **Radix UI** (components)
- **Lucide React** (icons)
- **Recharts** (charts)
- **PostgreSQL** for persistent data

---

## 🌐 Standards Alignment: DAK, FHIR, and SMART

HealthyMother is designed to align with leading digital health standards for interoperability and scalability:

### DAK (Digital Adaptation Kits)
- The app's workflows and data structures are inspired by WHO's DAKs, ensuring alignment with global best practices for maternal health.
- Patient journeys, visit schedules, and reporting follow DAK recommendations for digital health systems.

### FHIR (Fast Healthcare Interoperability Resources)
- Patient, encounter, and observation data structures are modeled after FHIR resources.
- The codebase includes utilities for converting app data to FHIR-compliant formats, enabling future integration with other FHIR-based systems.
- This ensures data can be exchanged with EHRs, national registries, and other health platforms.

### SMART (Substitutable Medical Applications, Reusable Technologies)
- HealthyMother is built as a modular, standards-based web application, making it easy to extend or integrate with SMART-on-FHIR platforms.
- The app's authentication and data access patterns are designed to be compatible with SMART principles, supporting secure, user-centric health data access in the future.

**In summary:** HealthyMother is ready for real-world health system integration, supporting DAK workflows, FHIR data models, and SMART app extensibility.

---

## 🤝 Contributing

We welcome contributions! To get started:

1. **Fork the repository**
2. **Create a new branch** for your feature or fix
3. **Commit your changes** with clear messages
4. **Push to your fork** and open a Pull Request

**Guidelines:**
- Keep code clean and well-commented
- Use consistent formatting (Prettier, ESLint)
- Test your changes locally before submitting
- For UI changes, add screenshots if possible
- For database features, ensure your code works with PostgreSQL and add migration scripts if needed
- For standards alignment, ensure FHIR/DAK/SMART compatibility is maintained

---

## ❓ FAQ

**Q: Is this app production-ready?**
- This is a robust system with persistent PostgreSQL storage and standards-based data models. Review security and compliance before production use.

**Q: Can I use this as a starter for my own project?**
- Yes! The codebase is modular and standards-aligned. Replace or extend as needed for your use case.

**Q: How do I reset the app data?**
- Use the database management tools or reset your PostgreSQL database.

---

## 📄 License

This project is currently **not licensed**. If you plan to share, open-source, or build upon this project, please add an appropriate license file.

---

## 🙏 Acknowledgements

- Inspired by real-world maternal health needs
- Built with love by the HealthyMother team

---

## 📬 Contact

For questions, feedback, or collaboration, please open an issue or contact the project maintainers. 