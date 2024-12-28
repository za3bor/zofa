require('dotenv').config(); // Load environment variables
const { S3Client, PutObjectCommand, DeleteObjectCommand  } = require('@aws-sdk/client-s3'); // Import S3Client and PutObjectCommand
const { fromEnv } = require('@aws-sdk/credential-provider-env'); // Load credentials from environment variables

// Configure AWS SDK for S3
const s3 = new S3Client({
  region: process.env.AWS_REGION, // Example: 'us-east-1'
  credentials: fromEnv(), // Automatically uses AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from environment variables
});

module.exports = { s3, PutObjectCommand, DeleteObjectCommand }; // Export both for use in other files
