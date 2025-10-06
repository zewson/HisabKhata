// Import required packages
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config(); // Loads environment variables from a .env file

// Import route handlers
const authRoutes = require('./routes/auth');
const customerAuthRoutes = require('./routes/customerAuth');
const customerRoutes = require('./routes/customers');
const dashboardRoutes = require('./routes/dashboard');

// Initialize the Express app
const app = express();

// Set the port for local development and deployment
const port = process.env.PORT || 3000;

// --- Middleware ---
app.use(cors()); // Enable Cross-Origin Resource Sharing
app.use(express.json()); // Enable the server to parse incoming JSON

// --- Database Connection ---
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('Successfully connected to MongoDB Atlas!'))
  .catch((err) => console.error('Database connection error:', err));

// --- API Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/auth/customer', customerAuthRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Base route to check if the server is running
app.get('/', (req, res) => {
  res.send('Hishab Khata App Server is running successfully.');
});

// Start the server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});