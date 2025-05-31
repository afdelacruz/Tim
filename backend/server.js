require('dotenv').config();

// Log loaded environment variables for verification (local development only)
console.log('--- Loaded Environment Variables ---');
console.log('PORT:', process.env.PORT);
console.log('PLAID_CLIENT_ID:', process.env.PLAID_CLIENT_ID ? 'Loaded' : 'NOT LOADED'); // Avoid logging the actual ID
console.log('PLAID_SECRET:', process.env.PLAID_SECRET ? 'Loaded' : 'NOT LOADED'); // Avoid logging the actual secret
console.log('PLAID_ENV:', process.env.PLAID_ENV);
console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'Loaded - ' + process.env.DATABASE_URL.substring(0, process.env.DATABASE_URL.indexOf('@') + 1) + '...' : 'NOT LOADED'); // Log part of the URL safely
console.log('----------------------------------');

const express = require('express');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors()); // Enable CORS for all routes
app.use(express.json()); // Middleware to parse JSON bodies

// Basic Health Check Endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'UP', message: 'Server is healthy' });
});

// Placeholder for future routes (e.g., auth, plaid, balances)
// app.use('/api/auth', authRoutes);
// app.use('/api/plaid', plaidRoutes);
// app.use('/api/balances', balanceRoutes);

// Basic Error Handling Middleware
// This should be the last middleware, to catch all errors
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err.stack || err);

    const statusCode = err.statusCode || 500; // Default to 500 Internal Server Error
    const errorCode = err.code || 'INTERNAL_SERVER_ERROR';
    const errorMessage = err.message || 'An unexpected error occurred.';

    res.status(statusCode).json({
        success: false,
        error: {
            code: errorCode,
            message: errorMessage
        }
    });
});

// Define Port
const PORT = process.env.PORT || 3001; // Railway provides PORT env var

// Start Server
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
