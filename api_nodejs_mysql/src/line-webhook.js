const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();

// ตั้งค่าให้ใช้ bodyParser เพื่อรับข้อมูล JSON จาก LINE
app.use(bodyParser.json());

// Token สำหรับการตอบกลับผู้ใช้
const LINE_CHANNEL_ACCESS_TOKEN = 'a765f14148a3ec0b4e23ba7628737819 ';

// Webhook ที่จะรับข้อมูลจาก LINE
app.post('/webhook', (req, res) => {
  const events = req.body.events;

  // ตรวจสอบว่ามี event หรือไม่
  if (events.length > 0) {
    events.forEach(event => {
      if (event.type === 'message' && event.message.type === 'text') {
        const message = event.message.text;

        // ประมวลผลข้อความที่ผู้ใช้ส่งมา (ในกรณีนี้คือข้อความเงินเข้า/เงินออก)
        const transaction = parseTransaction(message);
        console.log(transaction);

        // ตอบกลับผู้ใช้
        replyMessage(event.replyToken, `บันทึกข้อมูลการโอนเงินสำเร็จ: ${transaction.amount} บาท`);
      }
    });
  }

  // ส่งสถานะ 200 กลับไปให้ LINE เพื่อยืนยันว่ารับข้อมูลแล้ว
  res.sendStatus(200);
});

// ฟังก์ชันสำหรับตอบกลับผู้ใช้ผ่าน LINE Messaging API
function replyMessage(replyToken, text) {
  const url = 'https://api.line.me/v2/bot/message/reply';
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`
  };

  const body = {
    replyToken: replyToken,
    messages: [
      {
        type: 'text',
        text: text
      }
    ]
  };

  axios.post(url, body, { headers })
    .then(response => {
      console.log('Message sent successfully');
    })
    .catch(error => {
      console.error('Error sending message:', error);
    });
}

// ฟังก์ชันสำหรับดึงข้อมูลการโอนจากข้อความ
function parseTransaction(message) {
  const transaction = {};

  // ตรวจสอบว่าเป็นเงินเข้า หรือเงินออก
  if (message.startsWith('เงินเข้า')) {
    transaction.type = 'Income';
  } else if (message.startsWith('เงินออก')) {
    transaction.type = 'Expense';
  } else {
    transaction.type = 'Unknown';
  }

  // ดึงจำนวนเงินจากข้อความ
  const amountMatch = message.match(/โอน (\d+(\.\d{2})?) บาท/);
  if (amountMatch) {
    transaction.amount = parseFloat(amountMatch[1]);
  }

  // ดึงวันที่จากข้อความ
  const dateMatch = message.match(/วันที่ (\d{2}\/\d{2}\/\d{4})/);
  if (dateMatch) {
    const [day, month, year] = dateMatch[1].split('/');
    transaction.transaction_date = `${year}-${month}-${day}`; // เปลี่ยนรูปแบบเป็น YYYY-MM-DD
  }

  // ดึงเวลาจากข้อความ (ไม่บังคับ)
  const timeMatch = message.match(/@(\d{2}:\d{2})/);
  if (timeMatch) {
    transaction.transaction_time = timeMatch[1]; // เวลาถ้าอยากเก็บก็สามารถเก็บได้
  }

  return transaction;
}

// เริ่มเซิร์ฟเวอร์
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
