const express = require('express');
const postgresRoutes = require('./postgres.routes.js');
const mongoRoutes =require('./mongo.routes.js');

const router = express.Router();

router.use("/postgres", postgresRoutes);
router.use("/mongo", mongoRoutes);

module.exports = router;
