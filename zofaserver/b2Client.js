// b2Client.js
const B2 = require('backblaze-b2');
require('dotenv').config();

const b2 = new B2({
  applicationKeyId: process.env.applicationKeyId, // Backblaze B2 Application Key ID
  applicationKey: process.env.applicationKey, // Backblaze B2 Application Key
});

module.exports = b2;
