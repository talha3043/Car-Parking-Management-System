# ⚙️ Car Parking Management System - Backend API

This is the Express.js / Node.js API server for the **Car Parking Management System**.

## 🚀 Getting Started

### 📋 Prerequisites
*   [Node.js](https://nodejs.org/) (v16+)
*   [Microsoft SQL Server](https://www.microsoft.com/en-us/sql-server) database running locally or remotely.

### ⚙️ Installation
1.  Install backend dependencies:
    ```bash
    npm install
    ```
2.  Set up environment variables by creating a `.env` file:
    ```env
    PORT=5000
    DB_USER=your_sql_user
    DB_PASSWORD=your_sql_password
    DB_SERVER=localhost
    DB_DATABASE=CarParkingDB
    JWT_SECRET=your_jwt_secret_key
    ```
3.  Launch the API server:
    ```bash
    node server.js
    ```
    The server will listen at `http://localhost:5000`.

## 📂 Codebase Details
*   `server.js` - Express application definition, middleware config, SQL Server pooling, and route endpoints.
*   `package.json` - Server package declarations and dependencies (Express, Cors, Dotenv, SQL Server drivers).

For details on the full architecture, SQL Server database schemas, and frontend deployment, please refer to the **[Main Project README](../README.md)**.
