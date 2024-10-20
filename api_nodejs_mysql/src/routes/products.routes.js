import { Router } from "express";
import { 
  getTransactions, 
  createTransaction, 
  updateTransaction, 
  deleteTransaction, 
  getTransaction ,
  get_Category,
  createCategorys,
  getTransaction_g
} from "../controllers/transactions.controllers.js"; // เปลี่ยนชื่อไฟล์ให้สอดคล้องกับ transactions

const router = Router();

// ดึงธุรกรรมทั้งหมด
router.get("/transactions", getTransactions);
// ดึงธุรกรรมทั้งหมด
router.get("/categorie", get_Category);

// ดึงข้อมูลธุรกรรมตาม ID
router.get("/transaction/:id", getTransaction);
router.get("/transactions_g", getTransaction_g);

// สร้างธุรกรรมใหม่
router.post("/transaction", createTransaction);
router.post("/categories", createCategorys);

// อัปเดตธุรกรรมตาม ID
router.patch("/transaction/:id", updateTransaction);

// ลบธุรกรรมตาม ID
router.delete("/transaction/:id", deleteTransaction);

export default router;
