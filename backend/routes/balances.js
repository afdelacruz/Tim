const express = require('express');
const BalanceService = require('../services/BalanceService');
const { AppError, handleRouteError } = require('../utils/errorHandler');
const { authenticateToken } = require('../utils/authMiddleware');

const router = express.Router();

// GET /api/balances - Get current account balances for authenticated user
router.get('/', authenticateToken, async (req, res, next) => {
    try {
        const userId = req.user.id;
        const balanceService = new BalanceService();
        const balances = await balanceService.getCurrentBalancesForUser(userId);
        
        res.json({
            success: true,
            data: balances
        });
    } catch (error) {
        handleRouteError(error, res, next);
    }
});

module.exports = router;
