// server/routes/customerAuth.js
const express = require('express');
const router = express.Router();
const otpGenerator = require('otp-generator');
const jwt = require('jsonwebtoken');
const Customer = require('../models/Customer');
const auth = require('../middleware/auth'); // We'll reuse the admin auth middleware for the new endpoint

// POST /api/auth/customer/send-otp - Send OTP to customer
router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    const customer = await Customer.findOne({ phone });
    if (!customer) {
      return res.status(404).json({ message: 'This phone number is not registered as a customer.' });
    }

    const otp = otpGenerator.generate(6, { upperCaseAlphabets: false, specialChars: false, lowerCaseAlphabets: false });
    
    customer.otp = otp;
    customer.otpExpires = Date.now() + 10 * 60 * 1000; // OTP is valid for 10 minutes
    await customer.save();

    // In a real app, you would use an SMS gateway (like Twilio) to send the OTP.
    // For now, we will log it to the console for testing.
    console.log(`OTP for ${phone} is: ${otp}`);

    res.status(200).json({ message: 'OTP sent successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
});

// POST /api/auth/customer/verify-otp - Verify OTP and Login Customer
router.post('/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;
    const customer = await Customer.findOne({ 
      phone,
      otp,
      otpExpires: { $gt: Date.now() } // Check if OTP is not expired
    });

    if (!customer) {
      return res.status(400).json({ message: 'Invalid OTP or OTP has expired.' });
    }
    
    customer.otp = undefined; // OTP is used, so remove it
    customer.otpExpires = undefined;
    await customer.save();
    
    // Create JWT token for the customer
    const payload = { customer: { id: customer.id } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET || 'your_default_secret_key',
      { expiresIn: '1d' },
      (err, token) => {
        if (err) throw err;
        res.json({ token });
      }
    );
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
});

// A new secure route for the customer to get their own details
router.get('/me', auth, async (req, res) => {
    try {
        // Here, we use req.user.id which is set by the admin auth middleware.
        // We need to create a separate middleware for customers for a better design,
        // but for simplicity, we'll assume the customer ID is passed differently or
        // create a new customer-specific middleware.
        // Let's create one.
        res.status(501).json({ message: 'This part needs a customer-specific middleware.'})
    } catch(err) {
        res.status(500).send('Server Error');
    }
});


module.exports = router;