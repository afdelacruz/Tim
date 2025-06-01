const express = require('express');
const router = express.Router();
const BalanceHistoryService = require('../services/BalanceHistoryService');
const { authenticateToken } = require('../utils/authMiddleware');
const { handleRouteError } = require('../utils/errorHandler');

const balanceHistoryService = new BalanceHistoryService();

/**
 * GET /api/balance-history
 * Get balance history for the authenticated user
 * Query parameters:
 * - startDate: Start date in YYYY-MM-DD format (optional, defaults to 30 days ago)
 * - endDate: End date in YYYY-MM-DD format (optional, defaults to today)
 */
router.get('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { startDate, endDate } = req.query;

        // Validate date format if provided
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (startDate && !dateRegex.test(startDate)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid startDate format. Use YYYY-MM-DD.'
            });
        }
        if (endDate && !dateRegex.test(endDate)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid endDate format. Use YYYY-MM-DD.'
            });
        }

        // Validate date range
        if (startDate && endDate && new Date(startDate) > new Date(endDate)) {
            return res.status(400).json({
                success: false,
                error: 'startDate cannot be after endDate.'
            });
        }

        const balanceHistory = await balanceHistoryService.getBalanceHistoryForUser(
            userId,
            startDate,
            endDate
        );

        res.json({
            success: true,
            data: balanceHistory
        });
    } catch (error) {
        handleRouteError(res, error, 'Failed to get balance history');
    }
});

module.exports = router; 