const express = require('express');
const router = express.Router();
const otpGenerator = require('otp-generator');
const jwt = require('jsonwebtoken');
const Customer = require('../models/Customer');
const customerAuth = require('../middleware/customerAuth');

router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    const customer = await Customer.findOne({ phone });
    if (!customer) {
      return res.status(404).json({ message: 'This phone number is not registered as a customer.' });
    }
    const otp = otpGenerator.generate(6, { upperCaseAlphabets: false, specialChars: false, lowerCaseAlphabets: false });
    customer.otp = otp;
    customer.otpExpires = Date.now() + 10 * 60 * 1000;
    await customer.save();
    console.log(`OTP for ${phone} is: ${otp}`);
    res.status(200).json({ message: 'OTP sent successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;
    const customer = await Customer.findOne({ phone, otp, otpExpires: { $gt: Date.now() } });
    if (!customer) {
      return res.status(400).json({ message: 'Invalid OTP or OTP has expired.' });
    }
    customer.otp = undefined;
    customer.otpExpires = undefined;
    await customer.save();
    const payload = { customer: { id: customer.id } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
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

router.get('/me', customerAuth, async (req, res) => {
  try {
    const customer = await Customer.findById(req.customer.id).select('-otp -otpExpires');
    res.json(customer);
  } catch (err) {
    res.status(500).send('Server Error');
  }
});

module.exports = router;
