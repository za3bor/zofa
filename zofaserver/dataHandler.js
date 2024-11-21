const mysql = require("mysql2/promise");
const fs = require("fs");
const b2 = require("./b2Client");
require("dotenv").config();
const axios = require("axios"); // Add this line to import axios

// Configure database connection details (replace with your actual values)
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});


async function addNewCategory(category) {
  const { name } = category;
  try {
    const [existingCategories] = await pool.query(
      "SELECT * FROM category WHERE name = ?",
      [name]
    );
    if (existingCategories.length > 0) {
      return { success: false, message: "Category already exists" }; // Return a specific message if the category exists
    }

    const [results] = await pool.query(
      "INSERT INTO category (name) VALUES (?)",
      [name]
    );
    return {
      success: results.affectedRows > 0,
      message: "Category added successfully",
    }; // Return success message if inserted
  } catch (err) {
    console.error("Error inserting category:", err.message);
    throw err; // Re-throw the error for handling in the server code
  }
}

async function addNewNote(content) {
  try {
    if (!content.trim()) {
      throw new Error("Content cannot be empty");
    }
    
    const [result] = await pool.query(
      "INSERT INTO notes (content) VALUES (?)",
      [content]
    );
    return { id: result.insertId, content, message: "Note added successfully!" };
  } catch (err) {
    console.error("Error adding note:", err.message);
    throw { message: err.message || "Error adding note" };  // Send the error message back
  }
}


async function deleteNoteById(id) {
  try {
    const [result] = await pool.query(
      "DELETE FROM notes WHERE id = ?",
      [id]
    );
    if (result.affectedRows === 0) {
      return { message: "Note not found" }; // Return a message if no rows were affected
    }
    return { message: "Note deleted successfully!" }; // Return success message
  } catch (err) {
    console.error("Error deleting note:", err.message);
    throw new Error("Error deleting note");  // Throw error to be caught by the route handler
  }
}


async function getAllNotes() {
  try {
    const [rows] = await pool.query("SELECT * FROM notes");
    if (rows.length === 0) {
      return { message: "No notes found" };  // Return a message if no notes
    }
    return rows;
  } catch (err) {
    console.error("Error fetching notes:", err.message);
    throw { message: err.message || "Error fetching notes" };  // Send error message
  }
}


// Function to add a new coupon
async function addNewCoupon(code, percentage) {
  try {
    const [result] = await pool.query(
      "INSERT INTO coupons (code, percentage) VALUES (?, ?)",
      [code, percentage]
    );
    return { id: result.insertId, code, percentage }; // Return the new coupon data
  } catch (err) {
    console.error("Error adding coupon:", err.message);
    throw err; // Throw the error to be handled by the route
  }
}

// Function to get all coupons
async function getAllCoupons() {
  try {
    const [rows] = await pool.query("SELECT * FROM coupons");
    return rows.length === 0 ? [] : rows; // Return an empty array if no coupons found
  } catch (err) {
    console.error("Error fetching coupons:", err.message);
    throw err; // Throw the error to be handled by the route
  }
}

// Function to delete a coupon by ID
async function deleteCouponById(id) {
  try {
    const [result] = await pool.query(
      "DELETE FROM coupons WHERE id = ?",
      [id] // Use the provided ID to delete the coupon
    );
    return result; // Return the result of the deletion
  } catch (err) {
    console.error("Error deleting coupon:", err.message);
    throw err; // Throw the error to be handled by the route
  }
}

async function getAllCategories() {
  try {
    const [rows] = await pool.query("SELECT * FROM category");
    return rows.length === 0 ? [] : rows;
  } catch (err) {
    console.error("Error fetching categories:", err.message);
    throw err;
  }
}

async function uploadFileToB2(filePath, fileName) {
  try {
    await b2.authorize();

    const response = await b2.getUploadUrl({
      bucketId: process.env.bucketId,
    });

    const uploadUrl = response.data.uploadUrl;
    const uploadAuthToken = response.data.authorizationToken;

    const fileContent = fs.readFileSync(filePath);

    const uploadResponse = await b2.uploadFile({
      uploadUrl,
      uploadAuthToken,
      fileName,
      data: fileContent,
    });
    console.log("B2 success");
    return uploadResponse.data.fileUrl;
  } catch (error) {
    console.error("Error uploading file to B2:", error);
    throw error;
  }
}

// Function to delete the image from Backblaze B2
async function deleteImageFromB2(barcode) {
  const fileName = `${barcode}.jpg`; // Assuming the image is saved with .jpg extension

  const b2Url = 'https://api.backblazeb2.com/b2api/v2'; // Base URL for B2 API
  const authResponse = await axios.post(`${b2Url}/b2_authorize_account`, {
    // Your B2 authorization here
  });

  const { authorizationToken, apiUrl } = authResponse.data;

  const deleteResponse = await axios.delete(`${apiUrl}/b2_delete_file_version`, {
    headers: {
      Authorization: authorizationToken,
    },
    data: {
      fileName: fileName,
      fileId: barcode, // Replace with actual fileId if needed
    },
  });

  if (deleteResponse.status !== 204) {
    throw new Error("Failed to delete image from Backblaze");
  }
}

async function getFileFromB2(fileName) {
  try {
    // Authorize with B2
    const authResponse = await b2.authorize(); // Ensure b2 is initialized and configured
    const authorizationToken = authResponse.data.authorizationToken; // Get the token

    // Construct the download URL for the file
    const downloadUrl = `https://f003.backblazeb2.com/file/zofapic/${fileName}`;

    console.log("Attempting to download file from URL:", downloadUrl);

    // Fetch the file
    const response = await axios.get(downloadUrl, {
      headers: {
        Authorization: authorizationToken, // Use the token directly without 'Bearer'
      },
      responseType: "arraybuffer", // Set response type to binary
    });

    console.log("File downloaded successfully");
    return response.data; // This will be the binary data of the file
  } catch (error) {
    console.error(
      "Error downloading file from B2:",
      error.response?.data || error.message
    );
    throw error;
  }
}

module.exports = {
  addNewCategory,
  uploadFileToB2,
  getAllCategories,
  getFileFromB2,
  addNewNote,
  getAllNotes,
  deleteNoteById,
  addNewCoupon,
  getAllCoupons,
  deleteCouponById,
  //deleteImageFromB2,
};
