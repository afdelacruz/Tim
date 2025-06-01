const express = require('express');
const router = express.Router();
const AccountService = require('../services/AccountService');
const { authenticateToken } = require('../utils/authMiddleware');
const { handleRouteError } = require('../utils/errorHandler');

const accountService = new AccountService();

/**
 * GET /api/accounts
 * Get all accounts for the authenticated user with current balances
 */
router.get('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const accounts = await accountService.getUserAccounts(userId);

        res.json({
            success: true,
            data: {
                accounts,
                count: accounts.length
            }
        });
    } catch (error) {
        handleRouteError(res, error, 'Failed to get user accounts');
    }
});

/**
 * GET /api/accounts/stats
 * Get account statistics for the authenticated user
 */
router.get('/stats', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const stats = await accountService.getAccountStatistics(userId);

        res.json({
            success: true,
            data: stats
        });
    } catch (error) {
        handleRouteError(res, error, 'Failed to get account statistics');
    }
});

/**
 * GET /api/accounts/:id
 * Get a specific account by ID for the authenticated user
 */
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const accountId = req.params.id;

        const account = await accountService.getUserAccountById(accountId, userId);

        res.json({
            success: true,
            data: account
        });
    } catch (error) {
        handleRouteError(res, error, 'Failed to get account');
    }
});

/**
 * PUT /api/accounts/:id
 * Update account settings (nickname, visibility)
 */
router.put('/:id', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const accountId = req.params.id;
        const updates = req.body;

        const updatedAccount = await accountService.updateAccount(accountId, userId, updates);

        res.json({
            success: true,
            data: updatedAccount,
            message: 'Account updated successfully'
        });
    } catch (error) {
        handleRouteError(res, error, 'Failed to update account');
    }
});

/**
 * PUT /api/accounts/:id/categories
 * Update account category settings (inflow/outflow)
 */
router.put('/:id/categories', authenticateToken, async (req, res) => {
    try {
        console.log('=== Category Update Debug ===');
        console.log('User ID:', req.user.id);
        console.log('Account ID:', req.params.id);
        console.log('Request Body:', req.body);
        
        const userId = req.user.id;
        const accountId = req.params.id;
        const categoryUpdates = req.body;

        const result = await accountService.updateAccountCategories(accountId, userId, categoryUpdates);

        console.log('Update successful:', result);
        res.json(result);
    } catch (error) {
        console.error('=== Category Update Error ===');
        console.error('Error details:', error);
        console.error('Error stack:', error.stack);
        handleRouteError(res, error, 'Failed to update account categories');
    }
});

/**
 * DELETE /api/accounts/:id
 * Deactivate an account (soft delete)
 */
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const accountId = req.params.id;

        const result = await accountService.deactivateAccount(accountId, userId);

        res.json({
            success: true,
            data: result,
            message: 'Account deactivated successfully'
        });
    } catch (error) {
        handleRouteError(res, error, 'Failed to deactivate account');
    }
});

/**
 * GET /api/accounts/debug/schema
 * Debug endpoint to check database schema
 */
router.get('/debug/schema', authenticateToken, async (req, res) => {
    try {
        const db = require('../db');
        
        // Check if columns exist
        const schemaQuery = `
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'accounts' 
            ORDER BY ordinal_position;
        `;
        
        const { rows } = await db.query(schemaQuery);
        
        res.json({
            success: true,
            columns: rows
        });
    } catch (error) {
        console.error('Schema check error:', error);
        res.status(500).json({
            success: false,
            error: {
                code: 'SCHEMA_CHECK_ERROR',
                message: error.message
            }
        });
    }
});

module.exports = router; 