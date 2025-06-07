const express = require('express');
const BalanceService = require('../services/BalanceService');
const BalanceUpdateService = require('../services/BalanceUpdateService');
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

// POST /api/balances/update - Manually trigger balance updates for all users
router.post('/update', authenticateToken, async (req, res, next) => {
    try {
        console.log('🔄 Manual balance update triggered by user:', req.user.id);
        const balanceUpdateService = new BalanceUpdateService();
        await balanceUpdateService.fetchAndStoreBalancesForAllUsers();
        
        res.json({
            success: true,
            message: 'Balance update completed successfully',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('❌ Balance update failed:', error.message);
        handleRouteError(error, res, next);
    }
});

module.exports = router;
