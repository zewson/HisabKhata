const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Customer = require('../models/Customer');

router.get('/', auth, async (req, res) => {
  try {
    const customers = await Customer.find({}).sort({ name: 1 });
    res.json(customers);
  } catch (error) {
    res.status(500).send('Server Error');
  }
});

router.post('/', auth, async (req, res) => {
  try {
    const { name, phone } = req.body;
    const existingCustomer = await Customer.findOne({ phone });
    if (existingCustomer) {
      return res.status(400).json({ message: 'A customer with this phone number already exists.' });
    }
    const newCustomer = new Customer({ name, phone });
    await newCustomer.save();
    res.status(201).json(newCustomer);
  } catch (error) {
    res.status(500).send('Server Error');
  }
});

router.post('/:customerId/transactions', auth, async (req, res) => {
  try {
    const { amount, type } = req.body;
    const customer = await Customer.findById(req.params.customerId);
    if (!customer) return res.status(404).json({ message: 'Customer not found.' });
    
    customer.transactions.push({ amount, type });
    if (type === 'due') {
      customer.balance += Number(amount);
    } else if (type === 'payment') {
      customer.balance -= Number(amount);
    }
    await customer.save();
    res.json(customer);
  } catch (error) {
    res.status(500).send('Server Error');
  }
});

router.put('/:customerId/transactions/:transactionId', auth, async (req, res) => {
  try {
    const { amount, type } = req.body;
    const customer = await Customer.findById(req.params.customerId);
    if (!customer) return res.status(404).json({ message: 'Customer not found.' });
    
    const transaction = customer.transactions.id(req.params.transactionId);
    if (!transaction) return res.status(404).json({ message: 'Transaction not found.' });
    
    customer.balance += (transaction.type === 'payment' ? transaction.amount : -transaction.amount);
    transaction.amount = amount;
    transaction.type = type;
    customer.balance += (transaction.type === 'due' ? transaction.amount : -transaction.amount);
    
    await customer.save();
    res.json(customer);
  } catch (error) {
    res.status(500).send('Server Error');
  }
});

router.delete('/:customerId/transactions/:transactionId', auth, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.customerId);
    if (!customer) return res.status(404).json({ message: 'Customer not found.' });
    
    const transaction = customer.transactions.id(req.params.transactionId);
    if (!transaction) return res.status(404).json({ message: 'Transaction not found.' });
    
    customer.balance += (transaction.type === 'payment' ? transaction.amount : -transaction.amount);
    
    // Mongoose subdocument removal is slightly different in newer versions
    // Using pull is a reliable method
    customer.transactions.pull({ _id: req.params.transactionId });

    await customer.save();
    res.json(customer);
  } catch (error) {
    res.status(500).send('Server Error');
  }
});

module.exports = router;
