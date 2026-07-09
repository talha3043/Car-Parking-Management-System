# 🎨 Car Parking Management System - Frontend

This is the React.js client application for the **Car Parking Management System**.

## 🚀 Getting Started

### 📋 Prerequisites
Ensure you have [Node.js](https://nodejs.org/) installed on your machine.

### ⚙️ Installation
1.  Install the required packages:
    ```bash
    npm install
    ```
2.  Start the development server:
    ```bash
    npm start
    ```
    The application will run locally at `http://localhost:3000`.

## 📂 Folder Structure
*   `public/` - Static assets and `index.html`.
*   `src/` - React components, Hooks, and styles.
    *   `App.js` - Main client coordinator component.
    *   `App.css` - UI component styles.
    *   `index.js` - Entry point for the React application.
    *   `index.css` - Global theme variables and layouts.

## 🔗 Connection to Backend
This application communicates with the backend API via proxy configured in `package.json` (`"proxy": "http://localhost:5000"`).

For details on the full architecture, API endpoints, database setup, and backend deployment, please refer to the **[Main Project README](../README.md)**.
