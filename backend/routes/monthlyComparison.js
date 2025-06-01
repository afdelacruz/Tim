const express = require('express');
const router = express.Router();
const MonthlyComparisonService = require('../services/MonthlyComparisonService');
const { authenticateToken } = require('../utils/authMiddleware');
const { handleRouteError } = require('../utils/errorHandler');

const monthlyComparisonService = new MonthlyComparisonService();

/**
 * GET /api/monthly-comparison
 * Get monthly balance comparison for the authenticated user
 * Query parameters:
 * - date: Reference date in YYYY-MM-DD format (optional, defaults to current date)
 */
router.get('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { date } = req.query;

        let referenceDate = new Date();
        
        // Validate and parse date if provided
        if (date) {
            const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
            if (!dateRegex.test(date)) {
                return res.status(400).json({
                    success: false,
                    error: 'Invalid date format. Use YYYY-MM-DD.'
                });
            }
            
            referenceDate = new Date(date);
            if (isNaN(referenceDate.getTime())) {
                return res.status(400).json({
                    success: false,
                    error: 'Invalid date provided.'
                });
            }
        }

        const monthlyComparison = await monthlyComparisonService.getMonthlyComparison(
            userId,
            referenceDate
        );

        res.json({
            success: true,
            data: monthlyComparison
        });
    } catch (error) {
        handleRouteError(res, error, 'Failed to get monthly comparison');
    }
});

module.exports = router; 