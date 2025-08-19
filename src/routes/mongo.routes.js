const express = require("express");
const router = express.Router();

router.get("/", (req, res) => {
  res.json({ message: "Mongo API base route" });
});

module.exports = router;
