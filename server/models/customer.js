const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  amount: { type: Number, required: true },
  type: { type: String, required: true, enum: ['due', 'payment'] },
  date: { type: Date, default: Date.now }
});

const customerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true, unique: true },
  balance: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  otp: String,
  otpExpires: Date,
  transactions: [transactionSchema]
});

module.exports = mongoose.model('Customer', customerSchema);
