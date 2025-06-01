require('dotenv').config();

const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const plaidRoutes = require('./routes/plaid');
const balanceRoutes = require('./routes/balances');
const balanceHistoryRoutes = require('./routes/balanceHistory');
const { globalErrorHandler } = require('./utils/errorHandler');

const app = express();

// Environment validation
const requiredEnvVars = ['DATABASE_URL', 'PLAID_CLIENT_ID', 'PLAID_SECRET', 'PLAID_ENV'];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
    console.error('Missing required environment variables:', missingEnvVars);
    process.exit(1);
}

// Log loaded environment variables for verification (development only)
if (process.env.NODE_ENV !== 'production') {
    console.log('--- Loaded Environment Variables ---');
    console.log('PORT:', process.env.PORT);
    console.log('PLAID_CLIENT_ID:', process.env.PLAID_CLIENT_ID ? 'Loaded' : 'NOT LOADED');
    console.log('PLAID_SECRET:', process.env.PLAID_SECRET ? 'Loaded' : 'NOT LOADED');
    console.log('PLAID_ENV:', process.env.PLAID_ENV);
    console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'Loaded - ' + process.env.DATABASE_URL.substring(0, process.env.DATABASE_URL.indexOf('@') + 1) + '...' : 'NOT LOADED');
    console.log('JWT_ACCESS_SECRET:', process.env.JWT_ACCESS_SECRET ? 'Loaded' : 'NOT LOADED');
    console.log('JWT_REFRESH_SECRET:', process.env.JWT_REFRESH_SECRET ? 'Loaded' : 'NOT LOADED');
    console.log('----------------------------------');
}

// Middleware
app.use(cors()); // Enable CORS for all routes
app.use(express.json()); // Parse JSON bodies

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'UP', 
        message: 'Server is healthy',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/plaid', plaidRoutes);
app.use('/api/balances', balanceRoutes);
app.use('/api/balance-history', balanceHistoryRoutes);

// 404 handler for unmatched routes
app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        error: {
            code: 'NOT_FOUND',
            message: `Route ${req.method} ${req.originalUrl} not found`
        }
    });
});

// Global error handling middleware (must be last)
app.use(globalErrorHandler);

// Define Port
const PORT = process.env.PORT || 3001;

// Conditionally start server only if this file is run directly
if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`Server listening on port ${PORT}`);
        console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
}

module.exports = app;
