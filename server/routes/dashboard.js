const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Customer = require('../models/Customer');

// GET /api/dashboard/summary - Get key business metrics
router.get('/summary', auth, async (req, res) => {
  try {
    const summary = await Customer.aggregate([
      {
        $group: {
          _id: null,
          totalBalance: { $sum: '$balance' },
        },
      },
      {
        $project: {
          _id: 0,
          totalDue: '$totalBalance',
        },
      },
    ]);

    const result = {
      totalDue: summary.length > 0 ? summary[0].totalDue : 0,
    };
    res.json(result);
  } catch (error) {
    res.status(500).send('Server Error');
  }
});

module.exports = router;