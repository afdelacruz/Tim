const express = require('express');
const PlaidService = require('../services/PlaidService');
const { AppError, handleRouteError } = require('../utils/errorHandler');
const { authenticateToken } = require('../utils/authMiddleware');

const router = express.Router();

// POST /api/plaid/link-token - Generate Plaid Link token
router.post('/link-token', authenticateToken, async (req, res, next) => {
    try {
        const userId = req.user.id;
        const plaidService = new PlaidService();
        const linkToken = await plaidService.createLinkToken(userId);
        
        res.json({
            success: true,
            linkToken
        });
    } catch (error) {
        handleRouteError(error, res, next);
    }
});

// POST /api/plaid/exchange-token - Exchange public token for access token
router.post('/exchange-token', authenticateToken, async (req, res, next) => {
    try {
        const { publicToken } = req.body;
        
        if (!publicToken) {
            throw new AppError('Public token is required', 400, 'BAD_REQUEST');
        }
        
        const userId = req.user.id;
        const plaidService = new PlaidService();
        const result = await plaidService.exchangePublicToken(userId, publicToken);
        
        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        handleRouteError(error, res, next);
    }
});

module.exports = router;
