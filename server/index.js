// Import required packages
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config(); // Loads environment variables from a .env file

// Import route handlers from their respective files
const authRoutes = require('./routes/auth');
const customerAuthRoutes = require('./routes/customerAuth');
const customerRoutes = require('./routes/customers');
const dashboardRoutes = require('./routes/dashboard');

// Initialize the Express app
const app = express();

// Set the port, using the environment variable for deployment or 3000 for local development
const port = process.env.PORT || 3000;

// --- Middleware ---
// Enable Cross-Origin Resource Sharing to allow the Flutter app to communicate with the server
app.use(cors());
// Enable the server to parse incoming JSON data from request bodies
app.use(express.json());

// --- Database Connection ---
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('Successfully connected to MongoDB Atlas!'))
  .catch((err) => console.error('Database connection error:', err));

// --- API Routes ---
// Delegate specific API endpoints to their respective route handlers
app.use('/api/auth', authRoutes); // Handles admin login/registration
app.use('/api/auth/customer', customerAuthRoutes); // Handles customer OTP login
app.use('/api/customers', customerRoutes); // Handles all customer & transaction logic
app.use('/api/dashboard', dashboardRoutes); // Handles dashboard summary data

// A simple base route to confirm the server is running when you visit the URL
app.get('/', (req, res) => {
  res.send('Hishab Khata App Server is running successfully.');
});

// Start the server and listen for incoming requests on the specified port
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
