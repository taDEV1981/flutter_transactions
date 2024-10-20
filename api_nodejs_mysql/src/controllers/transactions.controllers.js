import { pool } from "../db.js";



// ดึงข้อมูลธุรกรรมตาม ID
export const getTransaction = async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM transactions WHERE id = ?",
      [req.params.id]
    );

    if (rows.length <= 0)
      return res.status(404).json({ message: "Transaction not found" });

    res.json(rows[0]);
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
export const getTransaction_g = async (req, res) => {
  try {
    // ทำการ JOIN ข้อมูลจากตาราง transactions และ categories เพื่อดึงข้อมูลทั้งหมด
    const [rows] = await pool.query(
      `
      SELECT 
        transactions.id, 
        transactions.type, 
        transactions.amount, 
        transactions.transaction_date, 
        transactions.created_at, 
        categories.name AS category_name, 
        categories.icon AS category_icon, 
        categories.color AS category_color
      FROM transactions
      LEFT JOIN categories ON transactions.category_id = categories.id
      `
    );

    // ถ้าไม่มีข้อมูล ส่งกลับ 404
    if (rows.length <= 0)
      return res.status(404).json({ message: "No transactions found" });

    // ส่งข้อมูลที่พบทั้งหมดกลับเป็น JSON
    res.json(rows);
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: "Internal server error" });
  }
};



// ดึงข้อมูลธุรกรรมทั้งหมด
export const getTransactions = async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM transactions");
    res.json(rows);
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
// ดึงข้อมูลธุรกรรมทั้งหมด
export const get_Category = async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM categories");
    res.json(rows);
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// สร้างข้อมูลธุรกรรมใหม่
export const createTransaction = async (req, res) => {
  const { category_id, type, amount, transaction_date } = req.body; // Removed user_id

  try {
    // Validate category_id
    const [categoryCheck] = await pool.query(
      "SELECT id FROM categories WHERE id = ?",
      [category_id]
    );
    if (categoryCheck.length === 0) {
      return res.status(400).json({ message: "Invalid category_id" });
    }

    // Insert the transaction without user_id
    const [result] = await pool.query(
      "INSERT INTO transactions (category_id, type, amount, transaction_date) VALUES (?, ?, ?, ?)",
      [category_id, type, amount, transaction_date]
    );

    res.status(201).json({
      message: "Transaction created",
      transactionId: result.insertId,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error" });
  }
};
// สร้างข้อมูลธุรกรรมใหม่
// transactions.controllers.js
export const createCategorys = async (req, res) => {
    const { name, icon, color } = req.body; // Adjust according to your needs
    try {
        // Your logic to create a category
        const [result] = await pool.query(
            "INSERT INTO categories (name, icon, color) VALUES (?, ?, ?)",
            [name, icon, color]
        );
        res.status(201).json({
            message: "Category created",
            categoryId: result.insertId,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Internal server error" });
    }
};


// ลบข้อมูลธุรกรรมตาม ID
export const deleteTransaction = async (req, res) => {
  try {
    const [result] = await pool.query(
      "DELETE FROM transactions WHERE id = ?",
      [req.params.id]
    );

    if (result.affectedRows <= 0)
      return res.status(404).json({ message: "Transaction not found" });

    res.sendStatus(204);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// อัปเดตข้อมูลธุรกรรมตาม ID
export const updateTransaction = async (req, res) => {
  const { id } = req.params;
  const { category_id, user_id, type, amount, transaction_date } = req.body;

  try {
    const [result] = await pool.query(
      `UPDATE transactions SET 
        category_id = IFNULL(?, category_id), 
        user_id = IFNULL(?, user_id), 
        type = IFNULL(?, type), 
        amount = IFNULL(?, amount), 
        transaction_date = IFNULL(?, transaction_date) 
      WHERE id = ?`,
      [category_id, user_id, type, amount, transaction_date, id]
    );

    if (result.affectedRows === 0)
      return res.status(404).json({ message: "Transaction not found" });

    const [rows] = await pool.query(
      "SELECT * FROM transactions WHERE id = ?",
      [id]
    );

    res.json(rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error" });
  }
};
